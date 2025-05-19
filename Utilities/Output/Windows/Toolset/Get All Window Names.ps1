Add-Type @"
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;
using System.Text;

public class __WindowLister_ {
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);
    
    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    public static List<string> GetAllWindowTitles() {
        List<string> windowTitles = new List<string>();
        EnumWindows((hWnd, lParam) => {
            StringBuilder windowText = new StringBuilder(256);
            if (GetWindowText(hWnd, windowText, windowText.Capacity) > 0) {
                windowTitles.Add(windowText.ToString() + " (hWnd: " + hWnd.ToString("X") + ")");
            } else {
                windowTitles.Add("Window with no title (hWnd: " + hWnd.ToString("X") + ")");
            }
            return true; // Continue enumeration
        }, IntPtr.Zero);
        return windowTitles;
    }
}
"@

# Get the list of all window titles
$titles = [__WindowLister_]::GetAllWindowTitles()

# Output the window titles
if ($titles.Count -eq 0) {
    Write-Host "No open windows found."
} else {
    $titles | ForEach-Object { Write-Host $_ }
}
