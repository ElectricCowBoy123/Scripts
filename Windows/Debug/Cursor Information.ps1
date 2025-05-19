Add-Type -AssemblyName System.Windows.Forms

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

while($True){
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
Write-Host "Percentage of Screen: X = $($percentageX, 2)%, Y = $($percentageY, 2)%"
Start-Sleep -Seconds 1
}