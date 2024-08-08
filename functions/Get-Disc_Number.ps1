function Get-DiscNumber {
    param (
        [string]$driveLetter
    )

    # Run MakeMKV to get the drive information
    $driveInfo = & "makemkvcon.exe" -r --cache=1 info disc:9999

    # Adjusted pattern to use single quotes and embedded double quotes properly
    $pattern = 'DRV:\d+,\d+,\d+,\d+,"[^"]*","[^"]*","' + "$driveLetter`:" + '"'
    
    # Filter the lines that match the pattern
    $matchedLine = $driveInfo | Select-String -Pattern $pattern

    # If a match is found, extract the drive number (first number after "DRV:")
    if ($matchedLine) {
        $driveNumber = $matchedLine -split "," | Select-Object -First 1
        return [int]($driveNumber -replace "DRV:", "")
    } else {
        Write-Output "No disc found in drive $driveLetter."
        Exit 1
    }
}

