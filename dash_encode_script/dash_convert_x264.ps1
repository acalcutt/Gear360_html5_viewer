$input = Read-Host 'What file do you want to convert?'

#$starttime = "-ss 00:00:52 "
#$endtime = "-t 00:00:10 "
$starttime = ""
$endtime = ""


If(Test-Path $input)
{
    $directory = Split-Path -Path $input
    $basename = [io.path]::GetFileNameWithoutExtension($input)
    $output_folder = "$directory\$basename\"
    echo "$directory - $basename - $output_folder"

    #Make the output directory
    Write-Host "Creating output directory $output_folder"
    New-Item -ItemType Directory -Force -Path $output_folder

    $outfile_basename = "$($output_folder)$($basename)"
    $manifest_name = "$($output_folder)manifest.mpd"

    $x264_DASH_PARAMS="-x264opts keyint=24:min-keyint=24:no-scenecut "
    $hwaccel_PARAMS="-hwaccel dxva2 -threads 4 "

    $outfile1 = "$($outfile_basename)_640x360_750k.mp4"
    Write-Host "Creating $outfile1"
    echo "ffmpeg.exe $($starttime)-hwaccel dxva2 -threads 4 -i $input $($endtime)-c:v libx264 -s 640x360 -b:v 750k $x264_DASH_PARAMS -an -f mp4 -dash 1 $outfile1"
    if (-Not (Test-Path $outfile1)) {Start-Process -Wait -FilePath "ffmpeg.exe" -ArgumentList "$($starttime)$($hwaccel_PARAMS)-i $input $($endtime)-c:v libx264 -s 640x360 -b:v 750k $x264_DASH_PARAMS -an -f mp4 -dash 1 $outfile1"}

    $outfile2 = "$($outfile_basename)_854x480_1000k.mp4"
    Write-Host "Creating $outfile2"
    if (-Not (Test-Path $outfile2)) {Start-Process -Wait -FilePath "ffmpeg.exe" -ArgumentList "$($starttime)$($hwaccel_PARAMS)-i $input $($endtime)-c:v libx264 -s 854x480 -b:v 1000k $x264_DASH_PARAMS -an -f mp4 -dash 1 $outfile2"}

    $outfile3 = "$($outfile_basename)_1280x720_2000k.mp4"
    Write-Host "Creating $outfile3"
    if (-Not (Test-Path $outfile3)) {Start-Process -Wait -FilePath "ffmpeg.exe" -ArgumentList "$($starttime)$($hwaccel_PARAMS)-i $input $($endtime)-c:v libx264 -s 1280x720 -b:v 2000k $x264_DASH_PARAMS -an -f mp4 -dash 1 $outfile3"}

    $outfile4 = "$($outfile_basename)_1920x1080_4000k.mp4"
    Write-Host "Creating $outfile4"
    if (-Not (Test-Path $outfile4)) {Start-Process -Wait -FilePath "ffmpeg.exe" -ArgumentList "$($starttime)$($hwaccel_PARAMS)-i $input $($endtime)-c:v libx264 -s 1920x1080 -b:v 4000k $x264_DASH_PARAMS -an -f mp4 -dash 1 $outfile4"}

    $outfile5 = "$($outfile_basename)_1920x1080_8000k.mp4"
    Write-Host "Creating $outfile5"
    if (-Not (Test-Path $outfile5)) {Start-Process -Wait -FilePath "ffmpeg.exe" -ArgumentList "$($starttime)$($hwaccel_PARAMS)-i $input $($endtime)-c:v libx264 -s 1920x1080 -b:v 8000k $x264_DASH_PARAMS -an -f mp4 -dash 1 $outfile5"}

    $outfile6 = "$($outfile_basename)_1920x1080_12000k.mp4"
    Write-Host "Creating $outfile6"
    if (-Not (Test-Path $outfile6)) {Start-Process -Wait -FilePath "ffmpeg.exe" -ArgumentList "$($starttime)$($hwaccel_PARAMS)-i $input $($endtime)-c:v libx264 -s 1920x1080 -b:v 12000k $x264_DASH_PARAMS -an -f mp4 -dash 1 $outfile6"}

    $outfile7 = "$($outfile_basename)_audio_128k.mp4"
    Write-Host "Creating $outfile7"
    if (-Not (Test-Path $outfile7)) {Start-Process -Wait -FilePath "ffmpeg.exe" -ArgumentList "$($starttime)$($hwaccel_PARAMS)-i $input $($endtime)-c:a aac -b:a 128k -vn $outfile7"}

    Write-Host "Creating $manifest_name"
    if (-Not (Test-Path $manifest_name)) {Start-Process -Wait -FilePath "MP4Box.exe" -ArgumentList "-dash 2000 -rap -frag-rap -profile onDemand $outfile1 $outfile2 $outfile3 $outfile4 $outfile5 $outfile6 $outfile7 -out $manifest_name"}
}
Else {"File $input does not exist"}
