# Configuration
$input = "C:\scripts\timelapse.mp4"
$starttime = "-ss 0 "
$endtime = "-t 00:00:03 "
$x264_DASH_PARAMS = " -r 24 -x264opts keyint=24:min-keyint=24:no-scenecut "
$hwaccel_PARAMS = "-hwaccel dxva2 -threads 4 "
$ffmpeg_path = "C:\scripts\ffmpeg-master-latest-win64-gpl-shared\bin\ffmpeg.exe"
$ffprobe_path = "C:\scripts\ffmpeg-master-latest-win64-gpl-shared\bin\ffprobe.exe"
$mp4box_path = "MP4Box.exe" #Make this a config var
$audio_bitrate = "128k"
$video_base_bitrate = "750k"
$isEquirectangular = $true # Set to $true if the input is equirectangular, $false otherwise

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
            return $null  # Or throw an error if you prefer
        }
    } else {
        Write-Warning "ffprobe failed to get resolution for '$filePath'"
        return $null # Or throw an error
    }
}

# Helper Function: Encode Video
function Encode-Video {
    param (
        [string]$inputFile,
        [string]$outputFile,
        [string]$resolution,
        [string]$bitrate
    )

    $params = "$($hwaccel_PARAMS)$($starttime)-i `"$inputFile`" $($endtime)-c:v libx264 -s $resolution -b:v $bitrate $x264_DASH_PARAMS -an -f mp4 -dash 1 `"$outputFile`""
    Write-Host "Creating $outputFile | $ffmpeg_path $params"
    if (-Not (Test-Path $outputFile)) { Start-Process -Wait -FilePath $ffmpeg_path -ArgumentList "$params" }
}

# --- Main Script ---

If (Test-Path $input) {
    $directory = Split-Path -Path $input
    $basename = [io.path]::GetFileNameWithoutExtension($input)
    $output_folder = "$directory\$basename\"
    Write-Host "$directory - $basename - $output_folder"

    # Make the output directory
    Write-Host "Creating output directory $output_folder"
    New-Item -ItemType Directory -Force -Path $output_folder

    $outfile_basename = "$($output_folder)$($basename)"

    # Get Source Resolution
    $sourceResolution = Get-VideoResolution -filePath $input
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

        # --- Encode Different Resolutions ---
        # Resolutions and Bitrates - Adjusted to respect max output
        $resolutions = @()
        if ($maxOutputWidth -ge 640 -and $maxOutputHeight -ge 360) {
            $baseBitrateValue = $video_base_bitrate -replace "k", ""  # Remove "k" and store as separate variable
            $calculatedBitrate = [math]::Round(([double]$baseBitrateValue * (360 / 720)))
            $resolutions += @{ Res = "640x360"; Bitrate = "$($calculatedBitrate)k"; }  # Add "k" back
        }
        if ($maxOutputWidth -ge 896 -and $maxOutputHeight -ge 504) {
            $baseBitrateValue = $video_base_bitrate -replace "k", ""  # Remove "k"
            $calculatedBitrate = [math]::Round(([double]$baseBitrateValue * (504 / 720)) * 1.333)
            $resolutions += @{ Res = "896x504"; Bitrate = "$($calculatedBitrate)k"; } #1000k
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

        # Create Thumbnail
        $thumbnail_name = "$($output_folder)thumbnail.jpg"
        $params8 = "$($starttime)-i `"$input`" -qscale:v 4 -vframes 1 `"$thumbnail_name`""
        Write-Host "Creating $thumbnail_name | $ffmpeg_path $params8"
        if (-Not (Test-Path $thumbnail_name)) { Start-Process -Wait -FilePath $ffmpeg_path -ArgumentList "$params8" }

        # Create Fallback MP4 (x264/AAC)
        $outfile0 = "$($output_folder)fallback.mp4"
        $fallbackWidth = [math]::Min(1280, $maxOutputWidth)
        $fallbackHeight = [math]::Min(720, $maxOutputHeight)
        $params0 = "$($hwaccel_PARAMS)$($starttime)-i `"$input`" $($endtime)-c:v libx264 -s $($fallbackWidth)x$($fallbackHeight) -b:v 2000k $x264_DASH_PARAMS -c:a aac -b:a $($audio_bitrate) -f mp4 -dash 1 `"$outfile0`""
        Write-Host "Creating $outfile0 | $ffmpeg_path $params0"
        if (-Not (Test-Path $outfile0)) { Start-Process -Wait -FilePath $ffmpeg_path -ArgumentList "$params0" }

        $video_files = @() # Array to hold the output file names for MP4Box

        foreach ($res in $resolutions) {
            $outfile = "$($outfile_basename)_$($res.Res)_$($res.Bitrate).mp4"
            Encode-Video -inputFile $input -outputFile $outfile -resolution $($res.Res) -bitrate $($res.Bitrate)
            $video_files += "`"$outfile`"" # Add the output file to the array
        }

        # --- Encode Audio ---
        #$outfile_audio = "$($outfile_basename)_audio_$($audio_bitrate).mp4"
        #$params_audio = "-i `"$input`" $($starttime)$($endtime)-c:a aac -b:a $($audio_bitrate) -vn `"$outfile_audio`""
        #Write-Host "Creating $outfile_audio | $ffmpeg_path $params_audio"
        #if (-Not (Test-Path $outfile_audio)) { Start-Process -Wait -FilePath $ffmpeg_path -ArgumentList "$params_audio" }
        #$video_files += "`"$outfile_audio`""

        # Create the DASH manifest file
        $manifest_name = "$($output_folder)Play.mpd"
        if ($isEquirectangular) {
            $manifest_name = "$($output_folder)Play.eq.mpd"
        }
        $params_mpd = "-dash 2000 -rap -frag-rap -profile onDemand $($video_files) -out `"$manifest_name`""
        Write-Host "Creating | $mp4box_path $params_mpd"
        if (-Not (Test-Path $manifest_name)) { Start-Process -Wait -FilePath $mp4box_path -ArgumentList "$params_mpd" }
    } else {
        Write-Error "Failed to get source resolution.  Aborting."
    }
}
Else { "File $input does not exist" }
