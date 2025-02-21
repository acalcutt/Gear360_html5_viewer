# Configuration
$source_folder = "\\192.168.0.12\e\360 Videos\Origional Files\ATV\2020-09-15 - Lee ME" # Replace with your input folder
$temp_folder = $source_folder + '\temp'
$output_folder = $source_folder + '\encoded'
$starttime = "0"
$endtime = "0"
$BinPath = $PSScriptRoot + '\bin'
$exiftool_path = $BinPath + "\exiftool.exe"
$ffmpeg_path = $BinPath + "\ffmpeg-master-latest-win64-gpl-shared\bin\ffmpeg.exe" # Needed for both encoding and checking
$ffprobe_path = $BinPath + "\ffmpeg-master-latest-win64-gpl-shared\bin\ffprobe.exe"
$packager_path = $BinPath + "\shaka-packager\packager-win-x64.exe"
$encoder = "libx264"
$videoArgs = "-c:v $encoder -pix_fmt yuv420p -profile:v high -level 4.2 -r 24 -x264opts keyint=24:min-keyint=24:no-scenecut"
$audio_bitrate = "128k"
$video_base_bitrate = "750k"
$has_audio = $false

# Function to get video resolution using ffprobe
function Get-VideoResolution {
    param([string]$filePath)

    # Use ffprobe with show_entries and CSV output
    $ffprobeOutput = & $ffprobe_path -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$filePath"

    # Parse the output (widthxheight)
    if ($ffprobeOutput) {
        $resolutionString = $ffprobeOutput.Trim()
        # Remove trailing 'x' if present
        if ($resolutionString.EndsWith("x")) {
            $resolutionString = $resolutionString.Substring(0, $resolutionString.Length - 1)
        }

        $resolution = $resolutionString.Split("x")
        if ($resolution.Length -eq 2) {
            $width = [int]$resolution[0]
            $height = [int]$resolution[1]
            return @{ Width = $width; Height = $height }
        } else {
            Write-Warning "Unexpected ffprobe output: '$ffprobeOutput'"
            return $null    # Or throw an error if you prefer
        }
    } else {
        Write-Warning "ffprobe failed to get resolution for '$filePath'"
        return $null # Or throw an error
    }
}

# Helper Function: Encode Video (to intermediate MP4)
function Encode-Video {
  param (
    [string]$inputFile,
    [string]$outputFile,
    [string]$resolution,
    [string]$bitrate
   )

   #Check if the outputfile already exists. if so, dont run
   if (Test-Path $outputFile) {
    Write-Host "Output file '$outputFile' already exists. Skipping encoding."
    return # Exit the function
   }

   $params = ""
   if ($starttime -and $starttime -ne "0") {
     $params += "-ss $($starttime) "
   }
   $params += "-i `"$inputFile`" "
   if ($endtime -and $endtime -ne "0") {
     $params += "-t $($endtime) "
   }

  $params += "$videoArgs -s $resolution -b:v $bitrate -an -f mp4 `"$outputFile`""
   Write-Host "Creating $outputFile | $ffmpeg_path $params"
   # -verbose can be added for debugging.
   try {
     $output = Start-Process -Wait -FilePath $ffmpeg_path -ArgumentList "$params" -PassThru # -verbose
     if ($output.ExitCode -ne 0) {
       Write-Error "FFmpeg failed with exit code $($output.ExitCode)"
     }
   } catch {
     Write-Error "Error running FFmpeg: $($_.Exception.Message)"
   }

   if (Test-Path $outputFile) {
     # Add Metadata Back In With ExifTool
     Write-Host "Adding 360 Metadata"
     & $exiftool_path -tagsFromFile "$inputFile" -sphericalvideoxml "$outputFile"
   }
}

# Function to build the packager command string for a single resolution
function Build-PackagerCommand {
    param (
        [string]$inputFile,
        [string]$resolution,
        [string]$output_folder,
        [string]$safe_resolution,
        [string]$bitrate
    )

    $width = $resolution.Split("x")[0]
    $height = $resolution.Split("x")[1]

    $output_segment = "$($safe_resolution)_$($bitrate).mp4"
    $playlist_name = "$($safe_resolution)_$($bitrate).m3u8"

    # Construct the packager input string. Using ffmpeg generated MP4 as input.
    $packager_input = "in=`"$inputFile`",stream=video,output=`"$output_segment`",playlist_name=`"$playlist_name`""
    return $packager_input
}

# Function to check if the input file has an audio stream using ffprobe
function Test-AudioStream {
    param([string]$filePath)

    try {
        $ffprobeOutput = & $ffprobe_path -v error -select_streams a:0 -show_entries stream=codec_type -of default=noprint_wrappers=1:nokey=1 "$filePath"
        if ($ffprobeOutput -match "audio") {
            return $true
        } else {
            return $false
        }
    } catch {
        Write-Warning "Error checking for audio stream: $($_.Exception.Message)"
        return $false
    }
}

# --- Main Script ---

# Check if the source folder exists
if (-not (Test-Path $source_folder -PathType Container)) {
    Write-Error "Source folder '$source_folder' does not exist."
    exit
}

# Get all video files in the source folder (you might want to filter by extension)
$video_files = Get-ChildItem -Path $source_folder -Filter "*.mp4" # Adjust filter as needed

# Process each video file
foreach ($input in $video_files) {

    Write-Host "Processing file: $($input.FullName)"

    # Store original FullName for later use (critical for audio encoding)
    $originalFullName = $input.FullName

    $directory = Split-Path -Path $originalFullName
    $basename = [io.path]::GetFileNameWithoutExtension($originalFullName)
    $temp_encode_folder = Join-Path $temp_folder $basename
    $finished_output_folder = Join-Path $output_folder $basename
    Write-Host "$directory - $basename - $temp_encode_folder"

    # Create output directory
    if (-not (Test-Path $temp_encode_folder)) {
        New-Item -ItemType Directory -Force -Path $temp_encode_folder | Out-Null
    }

    # Create output directory
    if (-not (Test-Path $finished_output_folder)) {
        New-Item -ItemType Directory -Force -Path $finished_output_folder | Out-Null
    }

    # Check for Audio Stream in Source
    $has_audio = Test-AudioStream -filePath $originalFullName
    Write-Host "Source file has audio: $($has_audio)"

    # Get Source Resolution
    $sourceResolution = Get-VideoResolution -filePath $originalFullName
    if ($sourceResolution) {
        $sourceWidth = $sourceResolution.Width
        $sourceHeight = $sourceResolution.Height

        Write-Host "Source Resolution: $($sourceWidth)x$($sourceHeight)"

        # Determine Maximum Output Resolution
        if ($sourceWidth -ge 7680 -and $sourceHeight -ge 3840) {
            $maxOutputWidth = 3840
            $maxOutputHeight = 2160
            Write-Host "Max output resolution: 3840x2160 (4K)"
        } elseif ($sourceWidth -ge 5760 -and $sourceHeight -ge 2880) {
            $maxOutputWidth = 1920
            $maxOutputHeight = 1080
            Write-Host "Max output resolution: 1920x1080 (1080p)"
        } else {
            $maxOutputWidth = $sourceWidth
            $maxOutputHeight = $sourceHeight
            Write-Host "Max output resolution: $($sourceWidth)x$($sourceHeight) (Source Resolution)"
        }

        # --- Define Resolutions and Bitrates ---
        $resolutions = @()
        if ($maxOutputWidth -ge 640 -and $maxOutputHeight -ge 360) {
            $baseBitrateValue = $video_base_bitrate -replace "k", ""
            $calculatedBitrate = [math]::Round(([double]$baseBitrateValue * (360 / 720)))
            $resolutions += @{ Res = "640x360"; Bitrate = "$($calculatedBitrate)k"; }
        }
        if ($maxOutputWidth -ge 896 -and $maxOutputHeight -ge 504) {
            $baseBitrateValue = $video_base_bitrate -replace "k", ""
            $calculatedBitrate = [math]::Round(([double]$baseBitrateValue * (504 / 720)) * 1.333)
            $resolutions += @{ Res = "896x504"; Bitrate = "$($calculatedBitrate)k"; }
        }
        if ($maxOutputWidth -ge 1280 -and $maxOutputHeight -ge 720) {
            $resolutions += @{ Res = "1280x720"; Bitrate = "2500k"; }
            $resolutions += @{ Res = "1280x720"; Bitrate = "5000k"; }
        }
        if ($maxOutputWidth -ge 1920 -and $maxOutputHeight -ge 1080) {
            $resolutions += @{ Res = "1920x1080"; Bitrate = "7500k"; }
            $resolutions += @{ Res = "1920x1080"; Bitrate = "10000k"; }
        }
        if ($maxOutputWidth -ge 2560 -and $maxOutputHeight -ge 1440) {
            $resolutions += @{ Res = "2560x1440"; Bitrate = "12500k"; }
        }
        if ($maxOutputWidth -ge 3840 -and $maxOutputHeight -ge 2160) {
            $resolutions += @{ Res = "3840x2160"; Bitrate = "17500k"; }
        }

        # --- Encode Video Streams (to intermediate MP4s) ---
        $encoded_files = @{} # Hash table to store paths to encoded files

        foreach ($res in $resolutions) {
            $safe_resolution = $res.Res -replace "x", "_" # Create a safe name for the resolution
            $outfile = Join-Path $temp_encode_folder "$($basename)_$($safe_resolution)_$($res.Bitrate).mp4" # Changed to use Join-Path

            #Checks if the $outfile alread exists.
            if (Test-Path $outfile) {
                Write-Host "Output file '$outfile' already exists. Skipping encoding."
                $encoded_files[$res.Res + '_' + $res.Bitrate] = $outfile # Store the path for packager input
            }
            else{
                Encode-Video -inputFile $originalFullName -outputFile $outfile -resolution $($res.Res) -bitrate $($res.Bitrate)
                $encoded_files[$res.Res + '_' + $res.Bitrate] = $outfile # Store the path for packager input
            }

        }

        # --- Encode Audio ---
        $packager_audio_input = $null # Initialize to null

        if ($has_audio) {

            $outfile_audio = Join-Path $temp_encode_folder "audio.mp4"

            if (Test-Path $outfile_audio) {
                Write-Host "Output file '$outfile_audio' already exists. Skipping audio encoding."
            }

            else{
                $params_audio = ""
                if ($starttime -and $starttime -ne "0") {
                    $params_audio += "-ss $($starttime) "
                }
                $params_audio += "-i `"$originalFullName`" " # Use originalFullName
                if ($endtime -and $endtime -ne "0") {
                    $params_audio += "-t $($endtime) "
                }

                $params_audio += "-vn -acodec aac -ab $($audio_bitrate) `"$outfile_audio`""
                Write-Host "Creating $outfile_audio | $ffmpeg_path $params_audio"
                try {
                    $output = Start-Process -Wait -FilePath $ffmpeg_path -ArgumentList "$params_audio" -PassThru # -verbose
                    if ($output.ExitCode -ne 0) {
                        Write-Error "FFmpeg failed with exit code $($output.ExitCode)"
                    }
                } catch {
                    Write-Error "Error running FFmpeg: $($_.Exception.Message)"
                }

            }

            $safe_audio_bitrate = $audio_bitrate -replace "k", ""
            $audio_output_segment = "audio_$($safe_audio_bitrate).mp4" # Changed to use Join-Path
            $audio_playlist_name = "audio.m3u8"
            $packager_audio_input = "in=`"$outfile_audio`",stream=audio,output=`"$audio_output_segment`",playlist_name=`"$audio_playlist_name`",hls_group_id=audio,hls_name=ENGLISH" # Set packager audio input
        }


        # --- Build Packager Command ---
        $packager_commands = @()

        foreach ($res in $resolutions) {
            $safe_resolution = $res.Res -replace "x", "_"
            $key = $res.Res + '_' + $res.Bitrate
            $packager_commands += Build-PackagerCommand -inputFile $encoded_files[$key] -resolution $($res.Res) -output_folder $temp_encode_folder -safe_resolution $safe_resolution -bitrate $res.Bitrate
        }

        # Add audio input stream if it has audio
        if ($has_audio -and $packager_audio_input) { # Only add if not null
            $packager_commands += $packager_audio_input
        }


        # Check if the master playlist file already exists. if so, dont run.
        $hls_master_playlist_output = Join-Path $finished_output_folder "Play.m3u8"
        $mpd_output = Join-Path $finished_output_folder "Play.mpd"

        if (Test-Path $hls_master_playlist_output) {
            Write-Host "Output file '$hls_master_playlist_output' already exists. Skipping packager."
        }

        else{
            echo $packager_commands

            # Common Packager Arguments
            $common_packager_args = @(
                "--hls_master_playlist_output", """$hls_master_playlist_output""",
                "--mpd_output", """$mpd_output"""
            )


            # Combine packager commands and common arguments into a single array
            $packager_arguments = @($packager_commands) + @($common_packager_args)


            Write-Host "Packager command: $packager_path $($packager_arguments)"
            try {
                $output = Start-Process -Wait -FilePath $packager_path -ArgumentList $packager_arguments -WorkingDirectory $finished_output_folder -PassThru
                if ($output.ExitCode -ne 0) {
                    Write-Error "Packager failed with exit code $($output.ExitCode)"
                }
            } catch {
                Write-Error "Error running Packager: $($_.Exception.Message)"
            }
        } # end of Test-Path $hls_master_playlist_output


        # --- Create Thumbnail and Fallback MP4 (if needed) ---
        # Thumbnail creation remains the same. Fallback MP4 creation is optional.

        $thumbnail_name = Join-Path $finished_output_folder "thumbnail.jpg" # added correct dir
        #Check if the $thumbnail_name file already exists. if so, dont run.
        if (Test-Path $thumbnail_name) {
            Write-Host "Output file '$thumbnail_name' already exists. Skipping thumbnail creation."
        }

        else{
            $thumbnail_width = 640
            $thumbnail_height = 360

            $params8 = ""
            if ($starttime -and $starttime -ne "0") {
                $params8 += "-ss $($starttime) "
            }

            $params8 += "-i `"$originalFullName`" -vf scale=$($thumbnail_width):$($thumbnail_height) -qscale:v 6 -vframes 1 `"$thumbnail_name`""
            try {
                $output = Start-Process -Wait -FilePath $ffmpeg_path -ArgumentList "$params8" -PassThru # -verbose
                if ($output.ExitCode -ne 0) {
                    Write-Error "FFmpeg failed with exit code $($output.ExitCode)"
                }
            } catch {
                Write-Error "Error running FFmpeg: $($_.Exception.Message)"
            }
        } # end of Test-Path $thumbnail_name



        $outfile0 = Join-Path $finished_output_folder "fallback.mp4" # added correct dir
        #Check if the fallback.mp4 file already exists. if so, dont run.
        if (Test-Path $outfile0) {
            Write-Host "Output file '$outfile0' already exists. Skipping fallback creation."
        }
        else{
            $fallbackWidth = [math]::Min(1280, $maxOutputWidth)
            $fallbackHeight = [math]::Min(720, $maxOutputHeight)
            $params0 = ""
            if ($starttime -and $starttime -ne "0") {
                $params0 += "-ss $($starttime) "
            }
            $params0 += "-i `"$originalFullName`" " #Use originalFullName
            if ($endtime -and $endtime -ne "0") {
                $params0 += "-t $($endtime) "
            }

            if ($has_audio) {
                $params0 += "-c:v libx264 -s $($fallbackWidth)x$($fallbackHeight) -b:v 2000k -c:a aac -b:a $($audio_bitrate) -f mp4 `"$outfile0`""
            } else {
                $params0 += "-c:v libx264 -s $($fallbackWidth)x$($fallbackHeight) -b:v 2000k -an -f mp4 `"$outfile0`""
            }
            try {
                $output = Start-Process -Wait -FilePath $ffmpeg_path -ArgumentList "$params0" -PassThru # -verbose
                if ($output.ExitCode -ne 0) {
                    Write-Error "FFmpeg failed with exit code $($output.ExitCode)"
                }
            } catch {
                Write-Error "Error running FFmpeg: $($_.Exception.Message)"
            }
        } # end of Test-Path $outfile0


    } else {
        Write-Error "Failed to get source resolution. Aborting."
    }
} # End foreach video_files

Write-Host "Processing complete."
