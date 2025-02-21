$ffprobeExecutable = "C:\scripts\ffmpeg-master-latest-win64-gpl-shared\bin\ffprobe.exe"
$FFmpegExecutable = "C:\scripts\ffmpeg-master-latest-win64-gpl-shared\bin\ffmpeg.exe"
$exiftoolExe = "\\192.168.0.12\e\360 Videos\360MultiStretch_script_by_Ricasan_df\bin\exiftool.exe"

# Directory containing the equirectangular images
$ImageDir = "\\192.168.0.12\e\360 Videos\Origional Files\output"
$OutImageDir = "\\192.168.0.12\e\360 Videos\Origional Files\output\reframed"

# Check if the output directory exists, and create it if it doesn't
if (!(Test-Path -Path $OutImageDir)) {
    Write-Host "Creating output directory: $OutImageDir"
    New-Item -ItemType Directory -Path $OutImageDir | Out-Null # Creates directory, suppresses output
}


# Loop through all MP4 files in the directory
Get-ChildItem -Path $ImageDir -Filter "*.mp4" | ForEach-Object {
  $InputFile = $_.FullName
  $OutputFile = Join-Path -Path $OutImageDir -ChildPath ($_.BaseName + "_reframed.mp4") # creates a new name with _reframed

  Write-Host "Metadata before reorientation:"
  & $ffprobeExecutable -v quiet -print_format json -show_format "$InputFile" | ConvertFrom-Json | Out-String
  & $exiftoolExe "$InputFile" | Out-String

  Write-Host "Processing: $InputFile"
  if (Test-Path -Path $OutputFile) {
   Write-Host "$OutputFile already exists, skipping"
  } else {
   # Execute the FFmpeg command. Construct arguments as an array.
   $params = @(
    "-i", "$InputFile",
    "-vf", "v360=input=e:output=e:yaw=0:pitch=-90", 
    "`"$OutputFile`""
   )
   Write-Host "Executing: $FFmpegExecutable $($params -join ' ')"
   & $FFmpegExecutable @params

   # Add Metadata Back In With ExifTool
    Write-Host "Adding 360 Metadata"
    & $exiftoolExe -overwrite_original -tagsfromfile "$InputFile" -all:all "$OutputFile"
  }

  Write-Host "Metadata after reorientation:"
  & $ffprobeExecutable -v quiet -print_format json -show_format "$OutputFile" | ConvertFrom-Json | Out-String
  & $exiftoolExe "$OutputFile" | Out-String
}

Write-Host "Batch processing complete."