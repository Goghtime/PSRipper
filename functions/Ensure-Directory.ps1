function Ensure-Directory {
    param (
        [string]$path
    )
    if (-Not (Test-Path -Path $path)) {
        New-Item -Path $path -ItemType Directory | Out-Null
        Write-Output "Directory $path created."
    } else {
        Write-Output "Directory $path already exists."
    }
}
