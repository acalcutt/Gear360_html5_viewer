<#
.SYNOPSIS
This script converts 360-degree videos and photos of 360 cameras from dual-fisheye to equirectangular projection.

.DESCRIPTION
360MultiStretch.ps1 Script by Ricasan_DF <ricasan_df[@]hotmail.com>
Brasilia, Brasil.

This script accepts input jpg Dual-Fisheye videos(mp4) or images(jpg) and converts them to equirectangular projection.
It applies perspective corrections and other transformations.
PRESUMES YOU HAVE THREE TOOLS: ffmpeg, ffprobe (ffmpeg.org) [script working with 6.0] and exiftool (exiftool.org) [script working with 12.65]
and those are accessible by your ambient variable PATH, OR YOU SHOULD CONFIG THE PATH IN PATH SECTION.
#>
#https://ffmpeg.org/ffmpeg-filters.html#v360
#https://github.com/ricasanbr/360MultiStretch.ps1
param (
    [string]$Mode
)
Add-Type -AssemblyName System.Windows.Forms
$InvokeDir = (pwd).Path
$ScriptPath = $PSScriptRoot

#IMPORTANT! IMPORTANT! IMPORTANT: If you are using notepad editor, go to menu VIEW and disable automatic line break (some lines here are too long like im trying making this one to bee so you can see how confuse that can become if you do not do that. trust me it is hard to see some config lines messed with what is only a comentary about an specific configuration or adjustment trust me ok? now you can breath)
#SKIP THAT PART, WHAT YOU WANT IS WAY DEEPER vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
function Get-FirstFilePath {
    param (
        [string]$DirectoryPath,
        [string]$FileType  # Image | Video
    )
    
    $extension = if ($FileType -eq "Image") { ".jpg" } elseif ($FileType -eq "Video") { ".mp4" } else { "" }
    $Files = Get-ChildItem -Path $DirectoryPath -File -Filter "*$extension"
    
    if ($Files.Count -eq 0) {
        Write-Host "No files of type '$extension' found in the directory '$DirectoryPath'."
        return $null
    }
    
    $FirstFile = $Files | Select-Object -First 1
    return $FirstFile.FullName
}

function Show-CustomFolderDialog {
    param (
        [string]$Description,
        [string]$InitialDirectory
    )

    # Create the form
    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Select Folder"
    $form.Width = 600
    $form.Height = 200
    $form.StartPosition = "CenterScreen"

    # Create the label
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Enter Folder Path:"
    $label.Location = New-Object System.Drawing.Point(10, 20)
    $label.AutoSize = $true
    $form.Controls.Add($label)

    # Create the textbox
    $textBox = New-Object System.Windows.Forms.TextBox
    $textBox.Location = New-Object System.Drawing.Point(150, 20)
    $textBox.Width = 300
    $form.Controls.Add($textBox)

    # Create the browse button
    $browseButton = New-Object System.Windows.Forms.Button
    $browseButton.Text = "Browse..."
    $browseButton.Location = New-Object System.Drawing.Point(460, 20)

    $browseButton.Add_Click({
        $folderBrowserDialog = New-Object System.Windows.Forms.FolderBrowserDialog
        $folderBrowserDialog.ShowNewFolderButton = $true
        $folderBrowserDialog.Description = $Description  # Use the passed description
        $folderBrowserDialog.RootFolder = [System.Environment+SpecialFolder]::Desktop
        $folderBrowserDialog.SelectedPath = $InitialDirectory # Use the initial directory
        $result = $folderBrowserDialog.ShowDialog()

        if ($result -eq "OK") {
            $textBox.Text = $folderBrowserDialog.SelectedPath
        }
    })
    $form.Controls.Add($browseButton)

    # Create the OK button
    $okButton = New-Object System.Windows.Forms.Button
    $okButton.Text = "OK"
    $okButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
    $okButton.Location = New-Object System.Drawing.Point(200, 80)
    $form.Controls.Add($okButton)

    # Create the Cancel button
    $cancelButton = New-Object System.Windows.Forms.Button
    $cancelButton.Text = "Cancel"
    $cancelButton.DialogResult = [System.Windows.Forms.DialogResult]::Cancel
    $cancelButton.Location = New-Object System.Drawing.Point(300, 80)
    $form.Controls.Add($cancelButton)

    # Set the form's AcceptButton and CancelButton
    $form.AcceptButton = $okButton
    $form.CancelButton = $cancelButton

    # Show the form as a dialog
    $result = $form.ShowDialog()

    if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
        return $textBox.Text  # Return the path entered in the textbox
    } else {
        return $null # Return null if the user cancelled
    }
}

#Selections of:
#Input
if ([string]::IsNullOrEmpty($Mode)) {
    Add-Type -AssemblyName System.Windows.Forms
    Add-Type -AssemblyName System.Drawing

    $form = New-Object System.Windows.Forms.Form
    $form.Size = New-Object System.Drawing.Size(600, 250)
    $form.Text = '360MultiStretcher.ps1 Script by Ricardo Leite'
    $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
    $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
    #$form.TopMost = $true
    $form.MaximizeBox = $false

    $buttonConfig = New-Object System.Windows.Forms.Button
    $buttonConfig.Location = New-Object System.Drawing.Point(5, 5)
    $buttonConfig.Size = New-Object System.Drawing.Size(50, 20)
    $buttonConfig.Text = 'Config'
    $buttonConfig.Add_Click({
            Start-Process "$ScriptPath\360MultiStretch.ps1"
        })
    $form.Controls.Add($buttonConfig)

    $label = New-Object System.Windows.Forms.Label
    $label.Location = New-Object System.Drawing.Point(190, 8)
    $label.Size = New-Object System.Drawing.Size(200, 20)
    $label.Font = New-Object System.Drawing.Font("Arial", 16, [System.Drawing.FontStyle]::Bold)
    $label.Text = "I want to process..."
    $form.Controls.Add($label)

    $PaintButton = {
        param(
            $sender,
            $e
        )
        $e.Graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $e.Graphics.FillEllipse([System.Drawing.Brushes]::SkyBlue, $sender.ClientRectangle)
        $boldFont = New-Object System.Drawing.Font($sender.Font.FontFamily, $sender.Font.Size, [System.Drawing.FontStyle]::Bold)
        $e.Graphics.DrawString($sender.Text, $boldFont, [System.Drawing.Brushes]::Black, 40, 70)
    }

    $buttonSingleFile = New-Object System.Windows.Forms.Button
    $buttonSingleFile.Location = New-Object System.Drawing.Point(25, 35)
    $buttonSingleFile.Size = New-Object System.Drawing.Size(150, 150)
    $buttonSingleFile.Text = 'One File'
    $buttonSingleFile.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $buttonSingleFile.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $buttonSingleFile.FlatAppearance.BorderSize = 0
    $buttonSingleFile.Add_Paint($PaintButton)
    $buttonSingleFile.Add_Click({
            $form.Tag = 'SingleFile'
            $form.Close()
        })
    $form.Controls.Add($buttonSingleFile)

    $buttonFolderImages = New-Object System.Windows.Forms.Button
    $buttonFolderImages.Location = New-Object System.Drawing.Point(205, 35)
    $buttonFolderImages.Size = New-Object System.Drawing.Size(150, 150)
    $buttonFolderImages.Text = 'Images'
    $buttonFolderImages.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $buttonFolderImages.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $buttonFolderImages.FlatAppearance.BorderSize = 0
    $buttonFolderImages.Add_Paint($PaintButton)
    $buttonFolderImages.Add_Click({
            $form.Tag = 'FolderImages'
            $form.Close()
        })
    $form.Controls.Add($buttonFolderImages)

    $buttonFolderVideos = New-Object System.Windows.Forms.Button
    $buttonFolderVideos.Location = New-Object System.Drawing.Point(385, 35)
    $buttonFolderVideos.Size = New-Object System.Drawing.Size(150, 150)
    $buttonFolderVideos.Text = 'Videos'
    $buttonFolderVideos.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
    $buttonFolderVideos.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
    $buttonFolderVideos.FlatAppearance.BorderSize = 0
    $buttonFolderVideos.Add_Paint($PaintButton)
    $buttonFolderVideos.Add_Click({
            $form.Tag = 'FolderVideos'
            $form.Close()
        })
    $form.Controls.Add($buttonFolderVideos)

    $form.ShowDialog()

    switch ($form.Tag) {
        "SingleFile" { $Mode = "SingleFile" }
        "FolderImages" { $Mode = "FolderImages" }
        "FolderVideos" { $Mode = "FolderVideos" }
        default { $Mode = $null }
    }

    if ([string]::IsNullOrEmpty($Mode)) {
        Write-Host "No mode selected. Exiting."
        exit
    }
}

if ($Mode -eq "SingleFile") {
    # Ask for input file
    $openFileDialog = New-Object System.Windows.Forms.OpenFileDialog
    $desktopPath = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::Desktop)
    $openFileDialog.InitialDirectory = $desktopPath
    #$openFileDialog.InitialDirectory = $InvokeDir
    $openFileDialog.Filter = "Supported files (*.mp4, *.jpg)|*.mp4;*.jpg|All files (*.*)|*.*"
    $openFileDialog.Title = "Select input file"
    $result = $openFileDialog.ShowDialog()

    if ($result -eq "OK") {
        $InputFile = $openFileDialog.FileName
        $desktopPath = $openFileDialog.SelectedPath
    }
    else {
        Write-Host "No file selected. Exiting."
        exit
    }
}
elseif ($Mode -eq "FolderImages") {
    # Ask for input folder (images)
    $description = "Select folder containing image files"
    $initialDirectory = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::MyPictures)
    $InputPath = Show-CustomFolderDialog -Description $description -InitialDirectory $initialDirectory

    if ($InputPath) {
        $desktopPath = $InputPath  # Store the selected path
        $InputFile = Get-FirstFilePath -DirectoryPath $InputPath -FileType "Image"
        if (!$InputFile) {
            Write-Warning "No image files found in the selected folder."
            # You might want to handle this case (e.g., exit or re-prompt)
        }
    }
    else {
        Write-Host "No folder selected. Exiting."
        exit
    }
}
elseif ($Mode -eq "FolderVideos") {
    # Ask for input folder (videos)
    $description = "Select folder containing video files"
    $initialDirectory = [System.Environment]::GetFolderPath([System.Environment+SpecialFolder]::MyVideos)
    $InputPath = Show-CustomFolderDialog -Description $description -InitialDirectory $initialDirectory

    if ($InputPath) {
        $desktopPath = $InputPath  # Store the selected path
        $InputFile = Get-FirstFilePath -DirectoryPath $InputPath -FileType "Video"
        if (!$InputFile) {
            Write-Warning "No video files found in the selected folder."
            # You might want to handle this case (e.g., exit or re-prompt)
        }
    }
    else {
        Write-Host "No folder selected. Exiting."
        exit
    }
}

# Output
if ([string]::IsNullOrEmpty($OutputPath)) {
    $description = "Select OUTPUT folder for stretched files"
    $initialDirectory = $desktopPath  # Use the last used desktop path
    $OutputPath = Show-CustomFolderDialog -Description $description -InitialDirectory $initialDirectory

    if (!$OutputPath) {
        Write-Host "No folder selected. Exiting."
        exit
    }
}

# HEEEEEEYYYYYYYYYY
#HERE!!!! ITS HERE!!!!! HEY!!!!!! HERE!!! uuuuHHHHHHHHUUUUUOOOOOOOOOUUUUUUUUU <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

#paths, filenames (and camera settings) for user config ###########################################################################################
$BinPath = $PSScriptRoot + '\bin'
$ffmpegExe = $BinPath + "\ffmpeg-master-latest-win64-gpl-shared\bin\ffmpeg.exe" # Needed for both encoding and checking
$ffprobeExe = $BinPath + "\ffmpeg-master-latest-win64-gpl-shared\bin\ffprobe.exe"
$exiftoolExe = $BinPath + "\exiftool.exe"   

$SUFFIX = "Stretched"           #Add this suffix to output filename

#FINE TUNNING AND ADJUSTMENTS OF OUTPUT############################################################################################################
$WIB = 3		#[SMOOTHNESS of transition beetween Left and Right]
#WIB: is Width of interpolation band in degrees (Overlapping)
#WIB: should (lol roflol) be lesser than overlap [ =< (FOV-180Â°)]
#WIB Optimal: is half of FOV-180.
#WIB Fun: beetween 2 to 12, try others!
#WIB: for darkened photos, higher are better,for lit, the smaller are better
#WIB: Too High may introduce "ghosts" at overlaps beetween right and left
#WIB: Too Low the transition between right and left may become rough
############################################################################################
$LeftPitch = 0	#[RIGHT VERTICAL] Pitch degrees [ - ⬇️ down     | +   up      ⬆️] 
$LeftYaw = 0	#[RIGHT LATERAL]    Yaw degrees [ - ⬅️ left     | + right     ➡️] 
$LeftRoll = 0	#[RIGHT ROLL]      Roll degrees [ - 🔃clockwise | + counter-cw🔄] should be enouth to compensate unleveling of camera relative to horizontal plane when photo was taken 
############################################################################################
$RightPitch = 0	#[LEFT VERTICAL]  Pitch degrees [ - ⬆️ up       | + down      ⬇️] 
$RightYaw = 0	#[LEFT LATERAL]     Yaw degrees [ - ⬅️ left     | + right     ➡️] 
$RightRoll = 0	#[LEFT ROLL]       Roll degrees [ - 🔃counter-cw| + clockwise 🔄] SHOULD BE THE INVERSE(+/-) AND EQUAL | | OF LeftRoll. Example $LeftRoll = -1 then $RightRoll = 1 ; or $LeftRoll = 2 then $RightRoll = -2. If not, the lenses in camera are twisted (or not symmetrical lol).
############################################################################################
$FOV = 193	    # FOV is Horizontal/Vertical fisheye degree field of view (adjust to your camera)
#FOV for Samsung Gear360(2017/v1): 193 #https://www.researchgate.net/publication/317724672_Dual-fisheye_lens_stitching_for_360-degree_imaging
#FOV for GoPro Fusion: 197	[?not confirmed] 
#FOV for Insta360 One X: 195	[?not confirmed] 
#FOV for Ricoh Theta V: 190	[?not confirmed] 
#FOV for Vuze XR: 187		[?not confirmed]
############################################################################################

#OK THATS ENOUGH, YOU ALREADY SNIFFED TOO MUCH. SAVE THE FILE CLOSE AND GO BACK!!!! <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<


# Internal use #
$InvokeDir = $PWD.Path

# Extract extension
if ([string]::IsNullOrEmpty($InputFile)) {
  Write-Host "The input file name is invalid." #invalid
  exit
}
$lastDotIndex = $InputFile.LastIndexOf('.') #No extension
if ($lastDotIndex -lt 0) {
  Write-Host "The input file name does not contain an extension."
  exit
}
$extensionIndex = $InputFile.LastIndexOf('.')
if ($extensionIndex -eq -1) {
    Write-Host "Filetype could not be determined. Please use a file with an extension."
    exit
}
$extension = $InputFile.Substring($extensionIndex).ToLower()
$InputFileNameOnly = [System.IO.Path]::GetFileName($InputFile)
$OutputFile = Join-Path $OutputPath "$($InputFileNameOnly -replace '\.[^.]+$')-$SUFFIX$extension"
#$TempDir = Join-Path $InvokeDir ".tmp"
$TempDir = "c:\temp\360MultiStretch.ps1"
$MergeMapFile = Join-Path $TempDir "mapping.png"						#merge mapping
$XmapFile = Join-Path $TempDir "Xmap.pgm"								#X mapping
$YmapFile = Join-Path $TempDir "Ymap.pgm"								#Y mapping
$RightEyeFile = Join-Path $TempDir "RightEye$extension"				    #Extracts Right eye half fisheye
$LeftEyeFile = Join-Path $TempDir "LeftEye$extension"					#Extracts Left eye half fisheye
$LeftFisheyeRemapFile = Join-Path $TempDir "LeftFisheyeRemap$extension"	#Move left eye to center
$DualFisheyeRemapFile = Join-Path $TempDir "DualFisheyeRemap$extension"
$EquirectangularFile = Join-Path $TempDir $InputFileNameOnly			#Create output but still without metadata.

#conteÃºdo para pano.xml
$360Metadata = @'
<?xml version="1.0"?>
<rdf:SphericalVideo xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#" xmlns:GSpherical="http://ns.google.com/videos/1.0/spherical/">
  <GSpherical:Spherical>true</GSpherical:Spherical>
  <GSpherical:Stitched>true</GSpherical:Stitched>
  <GSpherical:StitchingSoftware>360Stretch.ps1 by Ricardo Leite</GSpherical:StitchingSoftware>
  <GSpherical:ProjectionType>equirectangular</GSpherical:ProjectionType>
</rdf:SphericalVideo>
'@

# FUNCTIONS ##############################

function Get-GPUType {
    $gpus = Get-WmiObject -Query "SELECT * FROM Win32_VideoController"
    foreach ($gpu in $gpus) {
        $gpuName = $gpu.Name
        if ($gpuName -match "NVIDIA") {
            return "Nvidia"
        } elseif ($gpuName -match "AMD") {
            return "AMD"
        } elseif ($gpuName -match "Intel") {
            return "Intel"
        }
    }
    return "Unknown"
}

function PerformCameraMapping {
    param (
        [string]$InputFile,
        [string]$OutputFile,
        [string]$XmapFile,
        [string]$YmapFile,
        [string]$LeftEyeFile,
        [string]$RightEyeFile,
        [string]$LeftFisheyeRemapFile,
        [string]$DualFisheyeRemapFile,
        [string]$EquirectangularFile,
        [string]$MergeMapFile,
        [int]$FOV,
        [int]$Height,
        [int]$LeftYaw,
        [int]$LeftPitch,
        [int]$LeftRoll,
        [int]$RightYaw,
        [int]$RightPitch,
        [int]$RightRoll
    )
    
    $gpuType = Get-GPUType
    if ($gpuType -eq "Nvidia") {
        $encoder = "h264_nvenc"
    } elseif ($gpuType -eq "AMD") {
        $encoder = "h264_amf"
    } elseif ($gpuType -eq "Intel") {
        $encoder = "h264_qsv"
    } else {
        $encoder = "libx264"
    }
    Write-Host "encoder: $encoder"


    #& $ffmpegExe -f lavfi -i nullsrc=size=$($Height)`x$($Width/2) -vf "geq='clip(128-128/$($WIB)*(180-$($FOV)/($($Height)/2)*hypot(X-$($Height)/2,Y-$($Height)/2)),0,255)',v360=input=fisheye:output=e:ih_fov=$($FOV):iv_fov=$($FOV)" -frames:v 1 -update 1 -y $MergeMapFile
    & $ffmpegExe -f lavfi -i nullsrc=size=$($Height)`x$($Width/2) -vf "format=gray8,geq='clip(128-128/$($WIB)*(180-$($FOV)/($($Height)/2)*hypot(X-$($Height)/2,Y-$($Height)/2)),0,255)',v360=input=fisheye:output=e:ih_fov=$($FOV):iv_fov=$($FOV)" -frames:v 1 -update 1 -y $MergeMapFile
    #& $ffmpegExe -f lavfi -i nullsrc=size=$($Height)`x$($Width/2) -vf "format=gray16le,geq='clip(128-128/$($WIB)*(180-$($FOV)/($($Height)/2)*hypot(X-$($Height)/2,Y-$($Height)/2)),0,255)',v360=input=fisheye:output=e:ih_fov=$($FOV):iv_fov=$($FOV)" -frames:v 1 -update 1 -y $MergeMapFile

    Wait -For $MergeMapFile
    Write-Host "Mergemap ended"

    #& $ffmpegExe -f lavfi -i nullsrc=size=$($Height)`x$($Width/2) -vf geq=X -frames 1 -update 1 -y $XmapFile
    & $ffmpegExe -f lavfi -i nullsrc=size=$($Height)`x$($Width/2) -vf format=pix_fmts=gray16le,geq=X -frames 1 -update 1 -y $XmapFile

    Wait -For $XmapFile
    Write-Host "X mapping ended"

    & $ffmpegExe -f lavfi -i nullsrc=size=$($Height)`x$($Width/2) -vf format=pix_fmts=gray16le,geq=Y+$($LeftPitch) -frames 1 -update 1 -y $YmapFile
    #& $ffmpegExe -f lavfi -i nullsrc=size=$($Height)`x$($Width/2) -vf geq=Y+$($LeftPitch) -frames 1 -update 1 -y $YmapFile
    Wait -For $YmapFile
    Write-Host "Y mapping ended"
}

function PerformFileTransformations {
    param (
        [string]$InputFile,
        [string]$OutputFile
    )

    $gpuType = Get-GPUType
    if ($gpuType -eq "Nvidia") {
        $encoder = "h264_nvenc"
    } elseif ($gpuType -eq "AMD") {
        $encoder = "h264_amf"
    } elseif ($gpuType -eq "Intel") {
        $encoder = "h264_qsv"
    } else {
        $encoder = "libx264"
    }

    if ($FileType -eq "video") {
        $videoArgs = @("-c:v", $encoder)
    } elseif ($FileType -eq "image") {
        $videoArgs = @()
    }
    Write-Host "videoArgs: $($videoArgs -join ' ')"
     
    # Extracts Left fisheye from input
    #& $ffmpegExe -i $InputFile -vf crop=iw/2:ih:0:0 -q:v 1 -y $LeftEyeFile
    & $ffmpegExe -i $InputFile -vf crop=iw/2:ih:0:0  @videoArgs -q:v 1 -y $LeftEyeFile

    Wait -For $LeftEyeFile
    Write-Host "Extracts Left fisheye from input ended"

    #Extracts Right fisheye from input
    #& $ffmpegExe -i $InputFile -vf crop=iw/2:ih:iw/2:0 -q:v 1 -y $RightEyeFile
    & $ffmpegExe -i $InputFile -vf crop=iw/2:ih:iw/2:0  @videoArgs -q:v 1 -y $RightEyeFile
    Wait -For $RightEyeFile
    Write-Host "Extracts Right fisheye from input ended"

    # Remap Left Fisheye RGB
    #& $ffmpegExe -i $LeftEyeFile -i $XmapFile -i $YmapFile -q:v 1 -y $LeftFisheyeRemapFile
    #& $ffmpegExe -i $LeftEyeFile -i $XmapFile -i $YmapFile -lavfi "format=pix_fmts=rgb24, remap" -q:v 1 -y $LeftFisheyeRemapFile
    #& $ffmpegExe -i $LeftEyeFile -i $XmapFile -i $YmapFile -lavfi "format=pix_fmts=rgb24, remap" $videoArgs -q:v 1 -y $LeftFisheyeRemapFile
    #& $ffmpegExe -i $LeftEyeFile -i $XmapFile -i $YmapFile -lavfi "format=pix_fmts=rgb48le, remap" -q:v 1 -y $LeftFisheyeRemapFile
    & $ffmpegExe -i $LeftEyeFile -i $XmapFile -i $YmapFile -lavfi "format=pix_fmts=rgb24, remap" @videoArgs -q:v 1 -y $LeftFisheyeRemapFile

    Wait -For $LeftFisheyeRemapFile
    Write-Host "Remap Left Fisheye RGB ended"
    # Remap Dual Fisheye Stacked
   
    #&$ffmpegExe -i $LeftFisheyeRemapFile -i $RightEyeFile -filter_complex "[1:v]scale=-1:$($Height)[scaled];[0:v][scaled]hstack" -q:v 1 -y $DualFisheyeRemapFile
    &$ffmpegExe -i $LeftFisheyeRemapFile -i $RightEyeFile -filter_complex "[1:v]scale=-1:$($Height)[scaled];[0:v][scaled]hstack" @videoArgs -q:v 1 -y $DualFisheyeRemapFile
    #&$ffmpegExe -i $LeftFisheyeRemapFile -i $RightEyeFile -filter_complex "[1:v]scale=-1:$($Height)[scaled];[0:v][scaled]hstack=format=rgb48le" -q:v 1 -y $DualFisheyeRemapFile
    Wait -For $DualFisheyeRemapFile
    Write-Host "Remap Dual Fisheye Stacked ended"

    # To equirectangular projection: Center stretched left eye and splits stretched right eye (right eye around centered left eye: left portion at right of center, right portion at left of center )
    #& $ffmpegExe -i $DualFisheyeRemapFile -i $MergeMapFile -lavfi "[0]split[a][b];[a]crop=ih:iw/2:0:0,v360=input=fisheye:output=e:ih_fov=$($FOV):iv_fov=$($FOV):rorder=rpy:yaw=$($LeftYaw):pitch=$($LeftPitch):roll=$($LeftRoll)[c];[b]crop=ih:iw/2:iw/2:0,v360=input=fisheye:output=e:yaw=180+$($RightYaw):pitch=$($RightPitch):roll=$($RightRoll):ih_fov=$($FOV):iv_fov=$($FOV)[d];[1]format=gbrp[e];[c][d][e]maskedmerge" -q:v 1 -y $EquirectangularFile
    #& $ffmpegExe -i $DualFisheyeRemapFile -i $MergeMapFile -lavfi "[0]format=rgb24,split[a][b];[a]crop=ih:iw/2:0:0,v360=input=fisheye:output=e:ih_fov=$($FOV):iv_fov=$($FOV):rorder=rpy:yaw=$($LeftYaw):pitch=$($LeftPitch):roll=$($LeftRoll)[c];[b]crop=ih:iw/2:iw/2:0,v360=input=fisheye:output=e:yaw=180+$($RightYaw):pitch=$($RightPitch):roll=$($RightRoll):ih_fov=$($FOV):iv_fov=$($FOV)[d];[1]format=gbrp[e];[c][d][e]maskedmerge" -q:v 1 -y $EquirectangularFile
    #& $ffmpegExe -i $DualFisheyeRemapFile -i $MergeMapFile -lavfi "[0]format=rgb48le,split[a][b];[a]crop=ih:iw/2:0:0,v360=input=fisheye:output=e:ih_fov=$($FOV):iv_fov=$($FOV):rorder=rpy:yaw=$($LeftYaw):pitch=$($LeftPitch):roll=$($LeftRoll)[c];[b]crop=ih:iw/2:iw/2:0,v360=input=fisheye:output=e:yaw=180+$($RightYaw):pitch=$($RightPitch):roll=$($RightRoll):ih_fov=$($FOV):iv_fov=$($FOV)[d];[1]format=gbrp[e];[c][d][e]maskedmerge" -q:v 1 -y $EquirectangularFile
    & $ffmpegExe -i $DualFisheyeRemapFile -i $MergeMapFile -lavfi "[0]format=rgb48le,split[a][b];[a]crop=ih:iw/2:0:0,v360=input=fisheye:output=e:ih_fov=$($FOV):iv_fov=$($FOV):rorder=rpy:yaw=$($LeftYaw):pitch=$($LeftPitch):roll=$($LeftRoll)[c];[b]crop=ih:iw/2:iw/2:0,v360=input=fisheye:output=e:yaw=180+$($RightYaw):pitch=$($RightPitch):roll=$($RightRoll):ih_fov=$($FOV):iv_fov=$($FOV)[d];[1]format=gbrp[e];[c][d][e]maskedmerge" @videoArgs -q:v 1 -y $EquirectangularFile

    Wait -For $EquirectangularFile
    Write-Host "To equirectangular projection ended"

     #Re-insert metadata 
     if ($extension -eq ".jpg") {
        & $exiftoolExe -ProjectionType="equirectangular" -UsePanoramaViewer=True -FullPanoWidthPixels=$Width -FullPanoHeightPixels=$Height -CroppedAreaImageWidthPixels=$Width -CroppedAreaImageHeightPixels=$Height -CroppedAreaLeftPixels=0 -CroppedAreaTopPixels=0 -o $OutputFile $EquirectangularFile
    }
    elseif ($extension -eq ".mp4") {
        & $exiftoolExe -tagsfromfile $360MetadataFile -all:all -o $OutputFile $EquirectangularFile
    }
    else {
        Write-Host "Unsupported file type: $extension"
        exit
    }
    Wait -For $OutputFile
    Write-Host "Re-insert 360degree metadata ended"
}
Add-Type -AssemblyName System.Windows.Forms

function Finish {
    if ($Mode -eq "SingleFile") {
        ProcessFile -FilePath $InputFile
    }
    elseif ($Mode -eq "FolderImages") {
        ProcessFolder -InputPath $InputPath -FileType "Image"
    }
    elseif ($Mode -eq "FolderVideos") {
        ProcessFolder -InputPath $InputPath -FileType "Video"
    }
    Write-Host "Cleaning temporary processing files."
    #Remove-Item $TempDir -Force -Recurse

    Add-Type -AssemblyName System.Windows.Forms

    function Show-Dialog {
        $form = New-Object Windows.Forms.Form
        $form.Text = "Finished"
        $form.Width = 600
        $form.Height = 200
        $form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedSingle
        $form.StartPosition = [System.Windows.Forms.FormStartPosition]::CenterScreen
        $form.TopMost = $true

        $label = New-Object Windows.Forms.Label
        $label.Text = "Script ended"
        $label.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
        $label.AutoSize = $true
        $label.Location = New-Object Drawing.Point(240, 15)

        $acceptButton = New-Object Windows.Forms.Button
        $acceptButton.Text = "Close"
        $acceptButton.DialogResult = [System.Windows.Forms.DialogResult]::OK
        $acceptButton.Font = New-Object System.Drawing.Font("Arial", 12, [System.Drawing.FontStyle]::Bold)
        $acceptButton.Location = New-Object Drawing.Point(120, 90)
        $acceptButton.AutoSize = $true

        $form.Controls.Add($label)
        $form.Controls.Add($acceptButton)

        $result = $form.ShowDialog()

        if ($result -eq [System.Windows.Forms.DialogResult]::OK) {
            exit
        }
    }
    Show-Dialog
}

function Wait {
    param (
        [string]$For,
        [int]$InitialIncrement = 1, # Initial step of seconds for a retry
        [int]$Retries = 10 # Maximum n * power of 2 for the wait time (2^10 = 1024 seconds last step)
    )

    $i = 0
    $Increment = $InitialIncrement
    while ($true) {
        if (Test-Path $For) {
            Write-Host "Finished step processing."
            return $true
        }
        else {
            Write-Host "Still processing... ($i/$Retries) - Waiting for $Increment second(s)"
            Start-Sleep -Seconds $Increment
            $i++
            $Increment *= 2
        }
        
        if ($i -ge $Retries) {
            $userChoice = Read-Host "Retry limit reached. Would you like to continue waiting? (y/n)"
            if ($userChoice -eq 'n') {
                Write-Host "User choose to not continue. Exiting."
                exit
            }
            else {
                $i = 0
                $Increment = $InitialIncrement
                Write-Host "Still waiting..."
            }
        }
    }
}

function GetSize {
    param (
        [string]$FilePath
    )
    
    $dims = & $ffprobeExe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 $FilePath 2>&1
    $Width, $Height = $dims -split 'x'
    
    return $Width, $Height
}

# Function to process a single file
function ProcessFile {
  # Camera-based mapping
  $Width, $Height = GetSize $InputFile
  PerformCameraMapping -FOV $FOV -WIB $WIB -Height $Height -Width $Width -LeftPitch $LeftPitch -MergeMapFile $MergeMapFile -XmapFile $XmapFile -YmapFile $YmapFile

   # Determine file type based on extension
   $extension = [System.IO.Path]::GetExtension($InputFile).ToLower()
   if ($extension -eq ".mp4") {
      $FileType = "Video"
   } elseif ($extension -eq ".jpg") {
      $FileType = "Image"
   } else {
      Write-Host "Unsupported file type: $extension"
      return # Exit function if file type is unsupported
   }

  # Transformation based on the file
  $OutputFile = Join-Path $OutputPath "$($InputFileNameOnly -replace '\.[^.]+$')-$SUFFIX$extension"
  PerformFileTransformations -InputFile $InputFile -OutputFile $OutputFile

  Write-Host "File processing complete: $InputFile"
}

function ProcessFolder {
    param (
        [string]$InputPath,
        [string]$FileType  # Image | Video
    )

    $extension = if ($FileType -eq "Image") { ".jpg" } else { ".mp4" }

    $Files = Get-ChildItem -Path $InputPath -File -Filter "*$extension"
    if ($Files.Count -eq 0) {
		Write-Host "No files of type '$extension' found in the directory '$InputPath'."
        return
    }

    foreach ($File in $Files) {
        $tempFiles = Get-ChildItem -Path $TempDir
        foreach ($tempFile in $tempFiles) {
            if ($tempFile.Extension -eq ".mp4" -or $tempFile.Extension -eq ".jpg") {
                Remove-Item -Path $tempFile.FullName -Force
                while (Test-Path -Path $tempFile.FullName) {
                    Start-Sleep -Seconds 1
                    Write-Host "Waitting for temporaty folder cleaning..."
                }
            }
        }
        $InputFile = $File
        $Width, $Height = GetSize -FilePath $InputFile.FullName
        PerformCameraMapping -FOV $FOV -WIB $WIB -Height $Height -Width $Width -LeftPitch $LeftPitch -MergeMapFile $MergeMapFile -XmapFile $XmapFile -YmapFile $YmapFile
        $OutputFile = Join-Path $OutputPath "$($InputFile.BaseName)-$SUFFIX$extension"
        PerformFileTransformations -InputFile $InputFile.FullName -OutputFile $OutputFile
        Write-Host "File processing complete: $($File.FullName)"
    }
}

#I`VE ALREADY WARNED YOU... EAVESDROPPER! :D <<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<

# FILES AND FOLDERS CREATION #
Write-Host "TempDir is: $TempDir"
if ([string]::IsNullOrEmpty($TempDir)) {
    Write-Host "TempDir is empty or null. Please set it before proceeding."
}
elseif (-not (Test-Path $TempDir)) {
    try {
        if (-not (Test-Path $TempDir)) {
            New-Item -Path $TempDir -ItemType Directory
        }
    }
    catch {
        Write-Host "Error creating the directory: $_"
    }
}
else {
    Remove-Item "$TempDir\*" -Force -Recurse
}

while ((Get-ChildItem -Path $TempDir).Count -ne 0) {
    Start-Sleep -Seconds 1
}	#little hold for folders creation.

$360MetadataFile = Join-Path $TempDir "pano.xml"
& Set-Content -Path $360MetadataFile -Value $360Metadata
Wait -For $360MetadataFile

Write-Host "OutputPath is: $($OutputPath)"
if ([string]::IsNullOrEmpty($OutputPath)) {
    Write-Host "OutputPath is empty or null. Please set it before proceeding."
}
elseif (-not (Test-Path $OutputPath)) {
    Write-Host "Creating directory..."
    New-Item -Path $OutputPath -ItemType Directory
}
else {
    Write-Host "Directory already exists."
}

# MAIN EXECUTION #
Finish
