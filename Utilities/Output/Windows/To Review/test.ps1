<#
This script is dependant on a few axioms, these are the following:
- The accesibility icon in the settings has the ARGB value 255,14,141,220 at xy = 36,532
- The operating system this is running on is Windows 11 and thusly has the normal settings menu
- The settings switch dots are located at xy 1583,218 for notifications and 1555,146 for do not disturb
- The settings switch dots are either black or white, this is the case on dark and light mode in windows 11 regardless of the accent color
#>

if($($obj.Name -like "NT AUTHORITY*") -eq $True){
    throw "This Script Must be Ran as a User! $($_.Exception)"
}

Add-Type @"
using System;
using System.Runtime.InteropServices;

public class WindowMover {
    [DllImport("user32.dll")]
    public static extern IntPtr FindWindow(string lpClassName, string lpWindowName);

    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    public const uint SWP_NOZORDER = 0x0004;
    public const uint SWP_NOACTIVATE = 0x0010;
    public const int SW_MAXIMIZE = 3; // Command to maximize the window

    public static void MoveWindow(string windowTitle, int x, int y) {
        IntPtr hWnd = FindWindow(null, windowTitle);
        if (hWnd != IntPtr.Zero) {
            SetWindowPos(hWnd, IntPtr.Zero, x, y, 0, 0, SWP_NOZORDER | SWP_NOACTIVATE);
            ShowWindow(hWnd, SW_MAXIMIZE); // Maximize the window
        }
    }
}
"@

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -MemberDefinition '[DllImport("user32.dll")] public static extern void mouse_event(int flags, int dx, int dy, int cButtons, int info);' -Name U32 -Namespace W;

function Get-Screenshot {
    # Create a bitmap of the entire screen
    $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bitmap = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height

    # Create a graphics object from the bitmap
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)

    # Capture the screen
    $graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)

    # Dispose of the graphics object
    $graphics.Dispose()

    return $bitmap
}

function Test-SettingEnabled {
    [CmdletBinding()]
    Param (
        [Object]
        $dndIndicatorColor,
        [Float]
        $XPercentage,
        [Float]
        $YPercentage,
        [Boolean]
        $newState
    )

    # Get Primary Screen Resolution
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen
    $screenX = $screen.Bounds.Width
    $screenY = $screen.Bounds.Height

    $XClickPosition = [math]::Round($Xpercentage * $screenX)
    $YClickPosition = [math]::Round($Ypercentage * $screenY)

    [int]$YSettingsIndicatorPosition = [math]::Round(0.492592592592593 * $screenY)
    [int]$XSettingsIndicatorPosition = [math]::Round(0.01875 * $screenX)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Please wait..."
    $form.Size = New-Object System.Drawing.Size(300, 100)
    $form.StartPosition = "CenterScreen"
    $form.TopMost = $true
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Processing... Please do not interact."
    $label.ForeColor = [System.Drawing.Color]::FromArgb(255, 0, 0, 0)
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(50, 20)
    $form.Controls.Add($label)
    $form.Show()

    # Launch the settings app
    Start-Process "explorer.exe" "ms-settings:notifications"

    $settingsReady = $False
    while(!$settingsReady){
        $screenshot = Get-Screenshot
        $pixelColor = $screenshot.GetPixel($XSettingsIndicatorPosition, $YSettingsIndicatorPosition)
        if($pixelColor.ToArgb() -eq $([System.Drawing.Color]::FromArgb(255, 14, 141, 220)).ToArgb()){
            $settingsReady = $True
        }
    }

    # Sleep to take the screenshot
    Start-Sleep -Seconds 1

    [WindowMover]::MoveWindow("Settings", $screenX, $screenY)

    # Capture a screenshot
    $screenshot = Get-Screenshot
    
    $settingsProcess = Get-Process -Name "SystemSettings" -ErrorAction SilentlyContinue

    # Get the color of the pixel at the specified position of the black or white indicator color on the switch
    $pixelColor = $screenshot.GetPixel($XClickPosition, $YClickPosition)

    $state = $pixelColor.ToArgb() -eq $([System.Drawing.Color]::FromArgb(255, 0, 0, 0)).ToArgb() -or $pixelColor.ToArgb() -eq $([System.Drawing.Color]::FromArgb(255, 255, 255, 255)).ToArgb()
    
    if($newState -ne $state){
        $Xpercentage = $XClickPosition / $screenX
        $Ypercentage = $YClickPosition / $screenY

        [W.U32]::mouse_event(0x02 -bor 0x04 -bor 0x8000 -bor 0x01, $Xpercentage*65535, $Ypercentage*65535, 0, 0);
        #Write-Host "Clicked at $($XClickPosition),$($YClickPosition)"
    }

    Start-Sleep -Seconds 2

    if ($settingsProcess) {
        Stop-Process -Id $settingsProcess.Id -Force -ErrorAction SilentlyContinue
    }

    $form.Close()

    $screenshot.Dispose()
    # Check if the pixel color matches the white or black indicator color on the switch
    return $pixelColor.ToArgb() -eq $([System.Drawing.Color]::FromArgb(255, 0, 0, 0)).ToArgb() -or $pixelColor.ToArgb() -eq $([System.Drawing.Color]::FromArgb(255, 255, 255, 255)).ToArgb() # CHANGED HERE EQ TO NE
}

$settingsProcess = Get-Process -Name "SystemSettings" -ErrorAction SilentlyContinue

# Get Primary Screen Resolution
$screen = [System.Windows.Forms.Screen]::PrimaryScreen
$screenX = $screen.Bounds.Width
$screenY = $screen.Bounds.Height

if ($settingsProcess) {
    [WindowMover]::MoveWindow("Settings", $screenX, $screenY)
    Start-Sleep -Seconds 1
    Stop-Process -Id $settingsProcess.Id -Force
    Write-Host "Existing Settings Process Killed."
}

if (Test-SettingEnabled $([System.Drawing.Color]::FromArgb(255, 0, 0, 0)) 0.824479166666667 0.201851851851852 $False) {
    Write-Host "Do Not Disturb Enabled, Now Disabled."
} else {
    Write-Host "Do Not Disturb Not Enabled."
}

if (Test-SettingEnabled $([System.Drawing.Color]::FromArgb(255, 0, 0, 0)) 0.809895833333333 0.135185185185185 $True) {
    Write-Host "Notifications Enabled."
} else {
    Write-Host "Notifications Not Enabled, Now Enabled."
}

<#
# Debug
function Get-MousePosition {
    $mousePosition = [System.Windows.Forms.Cursor]::Position
    return $mousePosition
}
Write-Host "Press Ctrl+C to stop."
while ($true) {
    $position = Get-MousePosition
    Write-Host "Mouse Position: X=$($position.X), Y=$($position.Y)"
    Start-Sleep -Milliseconds 500  # Adjust the interval as needed
}
#>

<#
function Get-MousePosition-Percentage {
    Add-Type @"
        using System;
        using System.Runtime.InteropServices;
        public class Mouse {
            [DllImport("user32.dll")]
            public static extern bool GetCursorPos(out POINT lpPoint);
            public struct POINT {
                public int X;
                public int Y;
            }
        }
"@

    $point = New-Object Mouse+POINT
    [Mouse]::GetCursorPos([ref]$point)
    return $point
}

# Get the screen resolution
$screenWidth = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Width
$screenHeight = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds.Height

# Get the mouse position
$mousePosition = Get-MousePosition-Percentage

# Calculate the percentage
$percentageX = ($mousePosition.X / $screenWidth) * 100
$percentageY = ($mousePosition.Y / $screenHeight) * 100

# Output the results
Write-Host "Mouse Position: X = $($mousePosition.X), Y = $($mousePosition.Y)"
Write-Host "Percentage of Screen: X = $([math]::Round($percentageX, 2))%, Y = $([math]::Round($percentageY, 2))%"
#>