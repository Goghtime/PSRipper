# Define the root path
$rootPath = "D:\Ripper\Complete"

# Function to convert a string to Title Case
function Convert-ToTitleCase {
    param (
        [string]$text
    )
    $text = $text -replace "_", " "
    return (Get-Culture).TextInfo.ToTitleCase($text.ToLower())
}

# Get all directories in the root path and sort by LastWriteTime
$directories = Get-ChildItem -Path $rootPath -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 5

# Display directories for selection
Write-Host "Select the Movie you want to rename from the newest 5 Movie rips (or select 6 to exit):" -ForegroundColor Yellow
for ($i = 0; $i -lt $directories.Count; $i++) {
    Write-Host "$($i + 1): $($directories[$i].Name)" -ForegroundColor Cyan
}
Write-Host "6: Exit" -ForegroundColor Red

# Prompt user for selection
$selection = Read-Host "Enter the number corresponding to the Movie"

# Validate user input
if ($selection -eq "6") {
    Write-Host "Exiting without making changes." -ForegroundColor Green
    Exit
}

if ($selection -match '^\d+$' -and [int]$selection -ge 1 -and [int]$selection -le $directories.Count) {
    $dir = $directories[$selection - 1]

    # Find the first .mp4 file in the directory
    $mp4File = Get-ChildItem -Path $dir.FullName -Filter *.mp4 | Select-Object -First 1

    if ($mp4File) {
        # Prompt user for the new name
        $newName = Read-Host "Enter the new name for the selected Movie"
        $newName = Convert-ToTitleCase $newName

        # Rename the .mp4 file
        $newFileName = "$newName.mp4"
        $newFilePath = Join-Path -Path $mp4File.DirectoryName -ChildPath $newFileName

        if (-Not (Test-Path -Path $newFilePath)) {
            Rename-Item -Path $mp4File.FullName -NewName $newFileName
            Write-Host "Renamed file '$($mp4File.Name)' to '$newFileName'." -ForegroundColor Green
        } else {
            Write-Host "File '$newFileName' already exists. Skipping file renaming." -ForegroundColor Yellow
        }

        # Rename the directory
        $newDirPath = Join-Path -Path $dir.Parent.FullName -ChildPath $newName

        if (-Not (Test-Path -Path $newDirPath)) {
            Rename-Item -Path $dir.FullName -NewName $newDirPath
            Write-Host "Renamed directory '$($dir.Name)' to '$newName'." -ForegroundColor Green
        } else {
            Write-Host "Directory '$newName' already exists. Skipping directory renaming." -ForegroundColor Yellow
        }
    } else {
        Write-Host "No .mp4 file found in the directory '$($dir.Name)'. Skipping renaming." -ForegroundColor Yellow
    }
} else {
    Write-Host "Invalid selection. Please run the script again and select a valid number." -ForegroundColor Red
}

Write-Host "Operation completed." -ForegroundColor Green
