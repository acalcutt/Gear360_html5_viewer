$input = Read-Host 'What file do you want to convert?'
#$input = "Z:\360_0053.MP4"

$starttime = ""
$endtime = ""
#$starttime = "-ss 4 "
#$endtime = "-t 00:04:48 "

$x264_DASH_PARAMS=" -r 24 -x264opts keyint=24:min-keyint=24:no-scenecut "
$hwaccel_PARAMS="-hwaccel dxva2 -threads 4 "

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

    #Create Faillback MP4 (x264/AAC), for use when dash is not supported

    $outfile0 = "$($output_folder)fallback.mp4"
    $params0 = "$($hwaccel_PARAMS)$($starttime)-i $input $($endtime)-c:v libx264 -s 1280x720 -b:v 2000k $x264_DASH_PARAMS -c:a aac -b:a 128k -f mp4 -dash 1 $outfile0"
    Write-Host "Creating $outfile0 | ffmpeg.exe $params0"
    if (-Not (Test-Path $outfile0)) {Start-Process -Wait -FilePath "ffmpeg.exe" -ArgumentList "$params0"}

    #Create several different resolutions at different bitrates using ffmpeg

    $outfile1 = "$($outfile_basename)_640x360_750k.mp4"
    $params1 = "$($hwaccel_PARAMS)$($starttime)-i $input $($endtime)-c:v libx264 -s 640x360 -b:v 750k $x264_DASH_PARAMS -an -f mp4 -dash 1 $outfile1"
    Write-Host "Creating $outfile1 | ffmpeg.exe $params1"
    if (-Not (Test-Path $outfile1)) {Start-Process -Wait -FilePath "ffmpeg.exe" -ArgumentList "$params1"}

    $outfile2 = "$($outfile_basename)_896x504_1000k.mp4"
    $params2 = "$($hwaccel_PARAMS)$($starttime)-i $input $($endtime)-c:v libx264 -s 896x504 -b:v 1000k $x264_DASH_PARAMS -an -f mp4 -dash 1 $outfile2"
    Write-Host "Creating $outfile2 | ffmpeg.exe $params2"
    if (-Not (Test-Path $outfile2)) {Start-Process -Wait -FilePath "ffmpeg.exe" -ArgumentList "$params2"}

    $outfile3 = "$($outfile_basename)_1280x720_2000k.mp4"
    $params3 = "$($hwaccel_PARAMS)$($starttime)-i $input $($endtime)-c:v libx264 -s 1280x720 -b:v 2000k $x264_DASH_PARAMS -an -f mp4 -dash 1 $outfile3"
    Write-Host "Creating $outfile3 | ffmpeg.exe $params3"
    if (-Not (Test-Path $outfile3)) {Start-Process -Wait -FilePath "ffmpeg.exe" -ArgumentList "$params3"}

    $outfile4 = "$($outfile_basename)_1280x720_4000k.mp4"
    $params4 = "$($hwaccel_PARAMS)$($starttime)-i $input $($endtime)-c:v libx264 -s 1280x720 -b:v 4000k $x264_DASH_PARAMS -an -f mp4 -dash 1 $outfile4"
    Write-Host "Creating $outfile4 | ffmpeg.exe $params4"
    if (-Not (Test-Path $outfile4)) {Start-Process -Wait -FilePath "ffmpeg.exe" -ArgumentList "$params4"}

    $outfile5 = "$($outfile_basename)_1920x1080_8000k.mp4"
    $params5 = "$($hwaccel_PARAMS)$($starttime)-i $input $($endtime)-c:v libx264 -s 1920x1080 -b:v 8000k $x264_DASH_PARAMS -an -f mp4 -dash 1 $outfile5"
    Write-Host "Creating $outfile5 | ffmpeg.exe $params5"
    if (-Not (Test-Path $outfile5)) {Start-Process -Wait -FilePath "ffmpeg.exe" -ArgumentList "$params5"}

    $outfile6 = "$($outfile_basename)_1920x1080_12000k.mp4"
    $params6 = "$($hwaccel_PARAMS)$($starttime)-i $input $($endtime)-c:v libx264 -s 1920x1080 -b:v 12000k $x264_DASH_PARAMS -an -f mp4 -dash 1 $outfile6"
    Write-Host "Creating $outfile6 | ffmpeg.exe $params6"
    if (-Not (Test-Path $outfile6)) {Start-Process -Wait -FilePath "ffmpeg.exe" -ArgumentList "$params6"}

    $outfile7 = "$($outfile_basename)_audio_128k.mp4"
    $params7 = "-i $input $($starttime)$($endtime)-c:a aac -b:a 128k -vn $outfile7"
    Write-Host "Creating $outfile7 | ffmpeg.exe $params7"
    if (-Not (Test-Path $outfile7)) {Start-Process -Wait -FilePath "ffmpeg.exe" -ArgumentList "$params7"}

    $thumbnail_name = "$($output_folder)thumbnail.png"
    $params8 = "$($starttime)-i $input -vframes 1 $thumbnail_name"
    Write-Host "Creating $thumbnail_name | ffmpeg.exe $params8"
    if (-Not (Test-Path $thumbnail_name)) {Start-Process -Wait -FilePath "ffmpeg.exe" -ArgumentList "$params8"}

    #Create the dash manifest file

    $manifest_name = "$($output_folder)Play.mpd"
    $params9 = "-dash 2000 -rap -frag-rap -profile onDemand $outfile1 $outfile2 $outfile3 $outfile4 $outfile5 $outfile6 $outfile7 -out $manifest_name"
    Write-Host "Creating | MP4Box.exe $params9"
    if (-Not (Test-Path $manifest_name)) {Start-Process -Wait -FilePath "MP4Box.exe" -ArgumentList "$params9"}


}
Else {"File $input does not exist"}
