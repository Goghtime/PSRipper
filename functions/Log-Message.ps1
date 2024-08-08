# LoggingFunctions.ps1

function Log-Message {
    param (
        [string]$message,
        [string]$logFilePath
    )
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $logEntry = "$timestamp - $message"
    Add-Content -Path $logFilePath -Value $logEntry
    Write-Output $logEntry
}
