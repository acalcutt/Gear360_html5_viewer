# Configuration
$input = "\\192.168.0.12\e\360 Videos\Origional Files\ATV\2020-09-15 - Lee ME\360_0086.MP4"
$startTimeSeconds = 0  # Start time in seconds
$endTimeSeconds = 0   # Duration in seconds, use 0 for full duration
$x264_PARAMS = "-r 24 -x264opts keyint=24:min-keyint=24:no-scenecut"
$ffmpeg_path = "C:\scripts\ffmpeg-master-latest-win64-gpl-shared\bin\ffmpeg.exe"
$ffprobe_path = "C:\scripts\ffmpeg-master-latest-win64-gpl-shared\bin\ffprobe.exe"
$audio_bitrate = "128k"
$video_base_bitrate = "750k"
$isEquirectangular = $true # Set to $true if the input is equirectangular
$segment_time = 6  # HLS segment duration in seconds

# Define resolution ladder
$resolutions = @(
    @{ Width = 640; Height = 360; Bitrate = "800k"; AudioBitrate = "64k" },
    @{ Width = 854; Height = 480; Bitrate = "1400k"; AudioBitrate = "96k" },
    @{ Width = 1280; Height = 720; Bitrate = "2800k"; AudioBitrate = "128k" },
    @{ Width = 1280; Height = 720; Bitrate = "5000k"; AudioBitrate = "192k" },
    @{ Width = 1920; Height = 1080; Bitrate = "7500k"; AudioBitrate = "192k" },
    @{ Width = 1920; Height = 1080; Bitrate = "10000k"; AudioBitrate = "192k" },
    @{ Width = 2560; Height = 1440; Bitrate = "12500k"; AudioBitrate = "192k" },
    @{ Width = 3840; Height = 2160; Bitrate = "17500k"; AudioBitrate = "192k" }
)

# Function to get video resolution using ffprobe
function Get-VideoResolution {
    param([string]$filePath)
    $ffprobeOutput = & $ffprobe_path -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 "$filePath"
    if ($ffprobeOutput) {
        $resolutionString = $ffprobeOutput.Trim()
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
            return $null
        }
    } else {
        Write-Warning "ffprobe failed to get resolution for '$filePath'"
        return $null
    }
}

# Helper Function: Encode HLS Video Streams
function Encode-HLS {
    param (
        [string]$inputFile,
        [string]$outputFolder,
        [array]$resolutions,
        [int]$segmentDuration = 6,
        [int]$startTime = 0,
        [int]$duration = 0
    )

    # Create output directory if it doesn't exist
    if (-not (Test-Path $outputFolder)) {
        New-Item -ItemType Directory -Force -Path $outputFolder | Out-Null
    }

    # Determine if file has audio
    $hasAudio = $false
    $ffprobeAudioCheck = & $ffprobe_path -v error -select_streams a:0 -show_entries stream=codec_type -of default=noprint_wrappers=1:nokey=1 $inputFile
    if ($ffprobeAudioCheck) {
        $hasAudio = $true
    }

    # Process each resolution individually
    for ($i = 0; $i -lt $resolutions.Count; $i++) {
        $resWidth = $resolutions[$i].Width
        $resHeight = $resolutions[$i].Height
        $bitrate = $resolutions[$i].Bitrate
        $audioBitrate = $resolutions[$i].AudioBitrate

        # Create stream subdirectory
        $streamDir = Join-Path $outputFolder "stream_$i"
        if (-not (Test-Path $streamDir)) {
            New-Item -ItemType Directory -Force -Path $streamDir | Out-Null
        }

        # Build the FFmpeg command for this resolution
        $ffmpegArgs = @(
            "-threads", "4"
        )

        # Add start time if specified
        if ($startTime -gt 0) {
            $ffmpegArgs += "-ss", $startTime.ToString()
        }

        $ffmpegArgs += "-i", $inputFile

        # Add duration if specified
        if ($duration -gt 0) {
            $ffmpegArgs += "-t", $duration.ToString()
        }

        # Video scaling and encoding
        $ffmpegArgs += @(
            "-vf", "scale=$($resWidth):$($resHeight)",
            "-c:v", "libx264",
            "-b:v", $bitrate,
            "-r", "24",
            "-x264opts", "keyint=24:min-keyint=24:no-scenecut",
             "-preset", "medium",
        "-profile:v", "main"
        )

        # Audio encoding (if present)
        if ($hasAudio) {
            $ffmpegArgs += @(
                "-c:a", "aac",
                "-b:a", $audioBitrate,
                "-ac", "2"
            )
        }

        # HLS segment settings
        $segmentFilename = Join-Path $streamDir "segment_%03d.fMP4"
        $playlistName = Join-Path $streamDir "stream.m3u8"

        $ffmpegArgs += @(
            "-f", "hls",
            "-hls_time", $segmentDuration.ToString(),
            "-hls_playlist_type", "vod",
            "-hls_flags", "independent_segments",
            "-hls_segment_type", "fmp4",
            "-hls_segment_filename", $segmentFilename,
            $playlistName
        )

        # Display the command
        Write-Host "Creating HLS stream for resolution $($resWidth)x$($resHeight) with command:"
        Write-Host "$ffmpeg_path $($ffmpegArgs -join ' ')"

        # Execute the command
        try {
            & $ffmpeg_path $ffmpegArgs 2>&1 | Tee-Object -FilePath "ffmpeg_log_$($resWidth)x$($resHeight).txt"
        } catch {
            Write-Error "FFmpeg failed for resolution $($resWidth)x$($resHeight): $_"
        }
    }

    # Create the master playlist
    $masterPlaylistName = Join-Path $outputFolder "Play.m3u8"
    $masterPlaylistContent = "#EXTM3U`n#EXT-X-VERSION:3`n"
    for ($i = 0; $i -lt $resolutions.Count; $i++) {
        $resWidth = $resolutions[$i].Width
        $resHeight = $resolutions[$i].Height
        $bitrate = $resolutions[$i].Bitrate
        $playlistName = Join-Path "stream_$i" "stream.m3u8"
        $masterPlaylistContent += "#EXT-X-STREAM-INF:BANDWIDTH=$([int]($bitrate -replace 'k', '000')),RESOLUTION=$($resWidth)x$($resHeight),CODECS=`"avc1.42c01e,mp4a.40.2`"`n$playlistName`n"
    }
    $masterPlaylistContent | Out-File -FilePath $masterPlaylistName -Encoding utf8

    Write-Host "HLS conversion complete. Master playlist created in: $outputFolder"
}

# --- Main Script ---
if (Test-Path $input) {
    $directory = Split-Path -Path $input
    $basename = [io.path]::GetFileNameWithoutExtension($input)
    $output_folder = Join-Path $directory $basename

    Write-Host "Processing: $directory - $basename - $output_folder"

    # Create output directory if it doesn't exist
    if (-not (Test-Path $output_folder)) {
        New-Item -ItemType Directory -Force -Path $output_folder | Out-Null
    }

    # Get source resolution
    $sourceResolution = Get-VideoResolution -filePath $input
    if ($sourceResolution) {
        $sourceWidth = $sourceResolution.Width
        $sourceHeight = $sourceResolution.Height

        Write-Host "Source Resolution: $($sourceWidth)x$($sourceHeight)"

        # Determine maximum output resolution
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

        # Create thumbnail
        $thumbnail_name = Join-Path $output_folder "thumbnail.jpg"
        $thumbnailArgs = @(
            "-i", $input,
            "-qscale:v", "4",
            "-vframes", "1",
            $thumbnail_name
        )

        # Add start time if specified
        if ($startTimeSeconds -gt 0) {
            $thumbnailArgs = @("-ss", $startTimeSeconds.ToString()) + $thumbnailArgs
        }

        Write-Host "Creating thumbnail: $ffmpeg_path"
        if (-not (Test-Path $thumbnail_name)) {
            & $ffmpeg_path $thumbnailArgs
        }

        # Create fallback MP4 (1080p or source resolution if smaller)
        $fallbackWidth = [math]::Min(1920, $maxOutputWidth)
        $fallbackHeight = [math]::Min(1080, $maxOutputHeight)
        $outfile_fallback = Join-Path $output_folder "fallback.mp4"
        $fallbackArgs = @(
            "-hwaccel", "dxva2",
            "-threads", "4"
        )

        # Add start time if specified
        if ($startTimeSeconds -gt 0) {
            $fallbackArgs += "-ss", $startTimeSeconds.ToString()
        }

        $fallbackArgs += "-i", $input

        # Add duration if specified
        if ($endTimeSeconds -gt 0) {
            $fallbackArgs += "-t", $endTimeSeconds.ToString()
        }

        $fallbackArgs += @(
            "-c:v", "libx264",
            "-s", "$($fallbackWidth)x$($fallbackHeight)",
            "-b:v", "5000k",
            "-r", "24",
            "-x264opts", "keyint=24:min-keyint=24:no-scenecut",
            "-c:a", "aac",
            "-b:a", "192k",
            "-f", "mp4",
            $outfile_fallback
        )

        Write-Host "Creating fallback MP4: $ffmpeg_path"
        if (-not (Test-Path $outfile_fallback)) {
            & $ffmpeg_path $fallbackArgs
        }

        # Generate HLS streams
        Encode-HLS -inputFile $input -outputFolder $output_folder -resolutions $resolutions -segmentDuration $segment_time -startTime $startTimeSeconds -duration $endTimeSeconds

        Write-Host "Conversion complete. Output in: $output_folder"
    } else {
        Write-Error "Failed to get source resolution. Aborting."
    }
} else {
    Write-Error "Input file not found: $input"
}