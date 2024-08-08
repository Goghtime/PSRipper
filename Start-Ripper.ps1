param (
    [string]$dvdDriveLetter
)

# Validate parameter
if (-not $dvdDriveLetter) {
    Write-Output "Please provide the DVD drive letter as a parameter."
    Exit 1
}

# Load environment configuration
$env = Get-Content -Path "$PSScriptRoot\configs\env.json" | ConvertFrom-Json

# Define the path to the log file
$logFilePath = "$($env.rootPath)\logs\JobIDs.log"

# Define the path to the main script
$scriptPath = "$PSScriptRoot\scripts\Ripper.ps1"

# Build the argument string for the main script
$arguments = "-dvdDriveLetter `"$dvdDriveLetter`""

# Start the main script as a new process
$process = Start-Process -FilePath "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`" $arguments" -PassThru -WindowStyle Hidden

# Log the process ID to the log file
$processId = $process.Id
$logEntry = "ProcessID: $processId - Started at: $(Get-Date)"
Add-Content -Path $logFilePath -Value $logEntry

# Output the process ID to the console
Write-Output "Process started with ProcessID: $processId"
