<#
This script is dependant on a few axioms, these are the following:
- The accesibility icon in the settings is in the blue hue spectrum and is located in the square region of x = 0.1% y = 0.4% and x = 0.2%, y = 0.5% (roughly - see code below)
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
using System.Text;
using System.Threading;
using System.Collections.Generic;

public class _____WindowMoverAndLister1__ {
    [DllImport("user32.dll")]
    public static extern bool EnumWindows(EnumWindowsProc lpEnumFunc, IntPtr lParam);

    [DllImport("user32.dll")]
    public static extern bool SetWindowPos(IntPtr hWnd, IntPtr hWndInsertAfter, int X, int Y, int cx, int cy, uint uFlags);

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, int nCmdShow);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern int GetWindowText(IntPtr hWnd, StringBuilder lpString, int nMaxCount);

    public delegate bool EnumWindowsProc(IntPtr hWnd, IntPtr lParam);

    public const uint SWP_NOZORDER = 0x0004;
    public const uint SWP_NOACTIVATE = 0x0010;
    public const uint SWP_SHOWWINDOW = 0x0040;
    public const int SW_MAXIMIZE = 3; // Command to maximize the window
    public const int SW_SHOWNORMAL = 1;

    private static string targetWindowTitle;
    private static int targetX;
    private static int targetY;
    private static List<string> windowTitles = new List<string>();

    public static void ListAndMoveWindow(string windowTitle, int x, int y) {
        targetWindowTitle = windowTitle;
        targetX = x;
        targetY = y;

        EnumWindows(new EnumWindowsProc(EnumWindowCallback), IntPtr.Zero);

        // Print all collected window titles and handles
        /*
        foreach (var title in windowTitles) {
            Console.WriteLine(title);
        }
        */
    }

    private static bool EnumWindowCallback(IntPtr hWnd, IntPtr lParam) {
        StringBuilder windowText = new StringBuilder(256);
        GetWindowText(hWnd, windowText, windowText.Capacity);

        // Get the window title
        string title = windowText.ToString();

        // Add the window title and handle to the list
        // windowTitles.Add(title + " (hWnd: " + hWnd.ToString("X") + ")");

        // Check if the window title matches
        if (title == targetWindowTitle) {
            //Console.WriteLine("Found Window!");
            ShowWindow(hWnd, SW_SHOWNORMAL);
            SetWindowPos(hWnd, IntPtr.Zero, targetX, targetY, 0, 0, SWP_SHOWWINDOW);
            Thread.Sleep(1000);
            ShowWindow(hWnd, SW_MAXIMIZE); // Maximize the window
            return false; // Stop enumerating after moving the window
        }
        return true; // Continue enumerating
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

    # Get Screen Resolution
    $screen = [System.Windows.Forms.Screen]::PrimaryScreen
    $screenX = $screen.Bounds.Width
    $screenY = $screen.Bounds.Height

    $XClickPosition = [math]::Round($Xpercentage * $screenX)
    $YClickPosition = [math]::Round($Ypercentage * $screenY)

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Launching and Moving Settings Window..."
    $form.Size = New-Object System.Drawing.Size(300, 100)
    $form.StartPosition = "Manual"
    $form.Location = New-Object System.Drawing.Point([math]::Floor($screenX / 2 - $form.Width / 2), [math]::Floor($screenY / 2 - $form.Height / 2))
    $form.TopMost = $true
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Processing... Please do not interact."
    $label.ForeColor = [System.Drawing.Color]::FromArgb(255, 0, 0, 0)
    $label.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(50, 20)
    $form.Controls.Add($label)
    $form.Show()
    
    # Launch the settings app
    Start-Process "explorer.exe" "ms-settings:notifications"

    Start-Sleep -Seconds 1

    [_____WindowMoverAndLister1__]::ListAndMoveWindow("Settings", 1, 1)

    $form.Close()

    $form = New-Object System.Windows.Forms.Form
    $form.Text = "Getting Current Status of Settings Window..."
    $form.Size = New-Object System.Drawing.Size(300, 100)
    $form.StartPosition = "Manual"
    $form.Location = New-Object System.Drawing.Point([math]::Floor($screenX / 2 - $form.Width / 2), [math]::Floor($screenY / 2 - $form.Height / 2))
    $form.TopMost = $true
    $form.FormBorderStyle = "FixedDialog"
    $form.MaximizeBox = $false
    $form.MinimizeBox = $false
    $label = New-Object System.Windows.Forms.Label
    $label.Text = "Processing... Please do not interact."
    $label.ForeColor = [System.Drawing.Color]::FromArgb(255, 0, 0, 0)
    $label.BackColor = [System.Drawing.Color]::FromArgb(255, 255, 255, 255)
    $label.AutoSize = $true
    $label.Location = New-Object System.Drawing.Point(50, 20)
    $form.Controls.Add($label)
    $form.Show()

    $settingsReady = $False
    while(!$settingsReady){
        # Check Region
        $x1 = [math]::Round(0.0145833333333333 * $screenX)  # Top-left x 
        $y1 = [math]::Round(0.482407407407407 * $screenY)  # Top-left y 
        $x2 = [math]::Round(0.0229166666666667 * $screenX)  # Bottom-right x 
        $y2 = [math]::Round(0.500925925925926 * $screenY)  # Bottom-right y 

        for ($x = $x1; $x -le $x2; $x++) {
            for ($y = $y1; $y -le $y2; $y++) {
                $screenshot = Get-Screenshot
                $pixelColor = $screenshot.GetPixel($x, $y)
                if(($pixelColor.R -ge 0 -and $pixelColor.R -le 30) -and ($pixelColor.G -ge 100 -and $pixelColor.G -le 180) -and ($pixelColor.B -ge 200 -and $pixelColor.B -le 255)){
                    $settingsReady = $True
                    break
                }
            }
        }
    }

    # Sleep to take the screenshot
    Start-Sleep -Seconds 1

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

if ($settingsProcess) {
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