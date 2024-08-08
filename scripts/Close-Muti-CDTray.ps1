param (
    [string]$driveLetter,
    [ValidateSet("Eject", "Close")]
    [string]$action
)

# Function to eject a CD/DVD drive
function Eject-CDDrive {
    param (
        [string]$driveLetter
    )
    $driveLetter = $driveLetter.TrimEnd(":")
    (New-Object -ComObject Shell.Application).Namespace(17).ParseName("$driveLetter:`\").InvokeVerb("Eject")
}

# Function to close a CD/DVD drive
function Close-CDDrive {
    param (
        [string]$driveLetter
    )
    $driveLetter = $driveLetter.TrimEnd(":")
    Add-Type -TypeDefinition @'
    using System;
    using System.Runtime.InteropServices;
    namespace CDROM
    {
        public class Commands
        {
            [DllImport("winmm.dll")]
            public static extern int mciSendString(string command, string buffer, int bufferSize, IntPtr hwndCallback);
            public static void CloseDrive()
            {
                mciSendString("set cdaudio door closed", null, 0, IntPtr.Zero);
            }
        }
    }
'@
    [CDROM.Commands]::CloseDrive()
}

# Validate drive letter and perform the action
if ($driveLetter -and $action) {
    if ($action -eq "Eject") {
        Eject-CDDrive -driveLetter $driveLetter
        Write-Host "Ejected drive $driveLetter." -ForegroundColor Green
    } elseif ($action -eq "Close") {
        Close-CDDrive -driveLetter $driveLetter
        Write-Host "Closed drive $driveLetter." -ForegroundColor Green
    } else {
        Write-Host "Invalid action. Please provide 'Eject' or 'Close'." -ForegroundColor Red
    }
} else {
    Write-Host "Please provide both drive letter and action ('Eject' or 'Close')." -ForegroundColor Red
}

Write-Host "Operation completed." -ForegroundColor Green
