if (-not ("CDROM.Commands" -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
using System.ComponentModel;

namespace CDROM
{
    public class Commands
    {
        [DllImport("winmm.dll")]
        static extern Int32 mciSendString(string command, string buffer, int bufferSize, IntPtr hwndCallback);
        public static void Eject()
        {
             string rt = "";
             mciSendString("set CDAudio door open", rt, 127, IntPtr.Zero);
        }

        public static void Close()
        {
             string rt = "";
             mciSendString("set CDAudio door closed", rt, 127, IntPtr.Zero);
        }
    }
}
'@
}

[CDROM.Commands]::Eject()
Start-Sleep -Seconds 5  # Wait for 5 seconds before closing the tray (optional)
[CDROM.Commands]::Close()
