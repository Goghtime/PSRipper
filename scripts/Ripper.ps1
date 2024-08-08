param (
    [string]$dvdDriveLetter
)

# Validate parameter
if (-not $dvdDriveLetter) {
    Write-Output "Please provide the DVD drive letter as a parameter."
    Exit 1
}

$projectpath = Split-Path -Path $PSScriptRoot -Parent

# Import Ensure-Directory and Log-Message functions
Import-Module "$projectpath\functions\Ensure-Directory.ps1" -DisableNameChecking -Force
Import-Module "$projectpath\functions\Log-Message.ps1" -DisableNameChecking -Force
Import-Module "$projectpath\functions\Get-Disc_Number.ps1" -DisableNameChecking -Force

# Load environment configuration
$env = Get-Content -Path "$projectpath\configs\env.json" | ConvertFrom-Json
$subdirectories = @("Raw", "Transcode", "Complete", "logs")

# Ensure all required directories exist (except Complete)
foreach ($subdirectory in @("Raw", "Transcode")) {
    $fullPath = Join-Path -Path $env.rootPath -ChildPath "$subdirectory\$dvdDriveLetter"
    Ensure-Directory -path $fullPath
}
Ensure-Directory -path "$($env.rootPath)\$($subdirectories[2])"
Ensure-Directory -path "$($env.rootPath)\$($subdirectories[3])"

# Get process ID and define overall log file path
$processId = $PID
$overallLogFileName = "${processId}_Ripper_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$overallLogFilePath = Join-Path -Path "$($env.rootPath)" -ChildPath "$($subdirectories[3])\$overallLogFileName"

# Capture start time
$startTime = Get-Date
Log-Message "Process started at $startTime for drive $dvdDriveLetter" $overallLogFilePath

# Step 1: Get volume information of the DVD drive
Log-Message "Step 1: Getting volume information of the DVD drive." $overallLogFilePath
$dvdVolume = Get-Volume -DriveLetter $dvdDriveLetter

if ($dvdVolume -and $dvdVolume.FileSystemLabel) {
    $volumeLabel = $dvdVolume.FileSystemLabel
    Log-Message "Volume label retrieved: $volumeLabel" $overallLogFilePath
} else {
    $errorMessage = "No disc is present in drive $dvdDriveLetter or unable to retrieve the volume label."
    Log-Message $errorMessage $overallLogFilePath
    Exit 1
}

# Step 2: Run MakeMKV command
$DiskNumber = Get-DiscNumber -driveLetter $dvdDriveLetter


Log-Message "Step 2: Running MakeMKV command." $overallLogFilePath
$mkvlog = Join-Path -Path "$($env.rootPath)" -ChildPath "$($subdirectories[3])\mkv_${processId}_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"

& "makemkvcon.exe" mkv disc:$DiskNumber  all "$($env.rootPath)\$($subdirectories[0])\$dvdDriveLetter" *>&1 | Tee-Object -FilePath $mkvlog -Append | Out-Null
Log-Message "MakeMKV command completed. Log file: $mkvlog" $overallLogFilePath

# Step 3: Check MakeMKV log for success
Log-Message "Step 3: Checking MakeMKV log for success." $overallLogFilePath
$mkvlogContent = Get-Content $mkvlog

if ($mkvlogContent -contains "Operation successfully completed") {
    Log-Message "Operation successfully completed." $overallLogFilePath
} else {
    $errorMessage = "Operation did not complete successfully."
    Log-Message $errorMessage $overallLogFilePath
    Exit 1
}

# Step 4: Run HandBrakeCLI command
Log-Message "Step 4: Running HandBrakeCLI command." $overallLogFilePath
$hblog = Join-Path -Path $($env.rootPath) -ChildPath "$($subdirectories[3])\handbrake_${processId}_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$largestFile = Get-ChildItem -Path "$($env.rootPath)\$($subdirectories[0])\$dvdDriveLetter" | Where-Object { $_.PSIsContainer -eq $false } | Sort-Object -Property Length -Descending | Select-Object -First 1
$outputFilePath = Join-Path -Path $($env.rootPath) -ChildPath "$($subdirectories[1])\$dvdDriveLetter\$volumeLabel.mp4"

& HandBrakeCLI.exe -i $largestFile.FullName -o $outputFilePath -e nvenc_h265 -q 20 -B 160 *>&1 | Tee-Object -FilePath $hblog -Append | Out-Null
Log-Message "HandBrakeCLI command completed. Log file: $hblog" $overallLogFilePath

# Step 5: Check HandBrakeCLI log for success
Log-Message "Step 5: Checking HandBrakeCLI log for success." $overallLogFilePath
$hblogContent = Get-Content $hblog

if ($hblogContent -contains "Encode done!") {
    Log-Message "HandBrakeCLI operation was successfully completed." $overallLogFilePath
} else {
    $errorMessage = "HandBrakeCLI operation did not complete successfully."
    Log-Message $errorMessage $overallLogFilePath
    Exit 1
}

# Step 6: Move file to Complete folder
Log-Message "Step 6: Moving file to Complete folder." $overallLogFilePath
$destinationPath = Join-Path -Path $($env.rootPath) -ChildPath "$($subdirectories[2])\$volumeLabel"

# Ensure the destination directory exists
if (-Not (Test-Path -Path $destinationPath)) {
    New-Item -Path $destinationPath -ItemType Directory -Force | Out-Null
    Log-Message "Directory $destinationPath created." $overallLogFilePath
} else {
    Log-Message "Directory $destinationPath already exists." $overallLogFilePath
}

# Move the file to the destination directory
Move-Item -Path $outputFilePath -Destination $destinationPath -Force
Log-Message "File moved to $destinationPath." $overallLogFilePath

# Step 7: Clean up Raw and Transcode directories
Log-Message "Step 7: Cleaning up Raw and Transcode directories." $overallLogFilePath
Remove-Item -Path "$($env.rootPath)\$($subdirectories[0])\$dvdDriveLetter\*" -Recurse -Force
Log-Message "Raw directory cleaned up." $overallLogFilePath
Remove-Item -Path "$($env.rootPath)\$($subdirectories[1])\$dvdDriveLetter\*" -Recurse -Force
Log-Message "Transcode directory cleaned up." $overallLogFilePath

# Capture end time and calculate duration
$endTime = Get-Date
$duration = $endTime - $startTime
Log-Message "Process completed at $endTime for drive $dvdDriveLetter" $overallLogFilePath
Log-Message "Total duration: $duration" $overallLogFilePath

# Eject the CD tray using the custom script
Log-Message "Ejecting the CD tray for drive $dvdDriveLetter." $overallLogFilePath
& "$projectpath\scripts\Close-Muti-CDTray.ps1" -driveLetter $dvdDriveLetter -action "Eject"

# Final step - Log completion
Log-Message "All steps completed for drive $dvdDriveLetter." $overallLogFilePath
