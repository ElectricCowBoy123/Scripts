Add-Type @"
using System;
using System.Runtime.InteropServices;
using System.Threading;

public class WindowMoverClass____ {
    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    public const uint SWP_NOZORDER = 0x0004;
    public const uint SWP_NOACTIVATE = 0x0010;
    public const int SW_MAXIMIZE = 3; // Command to maximize the window
    public const int SW_SHOWNORMAL = 1;

    public static void MoveWindow(string windowTitle, int x, int y) {
        IntPtr hWnd = FindWindow(null, windowTitle);
        if (hWnd != IntPtr.Zero) {
            ShowWindow(hWnd, SW_MAXIMIZE);
            Thread.Sleep(1000);
            ShowWindow(hWnd, SW_SHOWNORMAL);
            Thread.Sleep(1000);
            SetWindowPos(hWnd, IntPtr.Zero, x, y, 0, 0, SWP_NOZORDER | SWP_NOACTIVATE);
            Thread.Sleep(1000);
            ShowWindow(hWnd, SW_MAXIMIZE); // Maximize the window
        }
    }
}
"@

Start-Process "notepad.exe"
Start-Sleep -Seconds 2
[WindowMoverClass____]::MoveWindow("Untitled - Notepad", 1, 1)
<#
Start-Sleep -Seconds 2
$notepadProcess = Get-Process -Name "Notepad" -ErrorAction SilentlyContinue
if($notepadProcess){
    Stop-Process -Id $notepadProcess.Id
}
#>
