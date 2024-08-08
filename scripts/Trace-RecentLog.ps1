param (
    [ValidateSet("MakeMKV", "HandBrake", "Ripper", "JobID")]
    [string]$log,
    $tail = 20,
    [int]$id
)

# Define log file prefixes based on log types
switch ($log) {
    "MakeMKV" { $logPrefix = "mk" }
    "HandBrake" { $logPrefix = "handbrake" }
    "Ripper" { $logPrefix = "ripper" }
    "JobID" { $logPrefix = "JobID" }
}

# Get log files in the directory with the specified prefix
if ($log -eq "JobID") {
    $latestLogFile = Get-ChildItem "D:\Ripper\logs\" | Where-Object { $_.Name -like "*$logPrefix*" } | Sort-Object LastWriteTime | Select-Object -Last 1
} elseif ($PSBoundParameters.ContainsKey('id')) {
    $latestLogFile = Get-ChildItem "D:\Ripper\logs\" | Where-Object { $_.Name -like "*$logPrefix*" -and $_.Name -like "*$id*" } | Sort-Object LastWriteTime | Select-Object -Last 1
} else {
    $latestLogFile = Get-ChildItem "D:\Ripper\logs\" | Where-Object { $_.Name -like "*$logPrefix*" } | Sort-Object LastWriteTime | Select-Object -Last 1
}

# Check if a log file was found
if ($latestLogFile) {
    $logFilePath = $latestLogFile.FullName
    $tailCount = $tail
    $title = "$log - PID $id"
    $command = "`$host.UI.RawUI.WindowTitle = `'$title`'; Get-Content -Path `'$logFilePath`' -Tail $tailCount -Wait"
    
    Start-Process powershell.exe -ArgumentList "-NoExit", "-Command", "$command"
} else {
    Write-Output "No log files found in the directory with prefix '$logPrefix'" + (if ($PSBoundParameters.ContainsKey('id')) { " and PID '$id'" } else { "" }) + "."
}
