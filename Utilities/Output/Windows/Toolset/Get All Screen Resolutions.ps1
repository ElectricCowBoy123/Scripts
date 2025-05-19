# Load the necessary assembly
Add-Type -AssemblyName System.Windows.Forms

# Get all connected screens
$screens = [System.Windows.Forms.Screen]::AllScreens

# Initialize total width and height
$totalWidth = 0
$totalHeight = 0

# Output the number of screens
Write-Host "Number of screens: $($screens.Count)"

# Loop through each screen to get its resolution and position
for ($i = 0; $i -lt $screens.Count; $i++) {
    $screen = $screens[$i]
    $width = $screen.Bounds.Width
    $height = $screen.Bounds.Height
    $x = $screen.Bounds.X
    $y = $screen.Bounds.Y

    # Check if the screen is the primary screen
    $isPrimary = if ($screen.Primary) { " (Primary)" } else { "" }

    # Output the resolution, position, and monitor name of each screen
    Write-Host "Monitor $($i + 1): Resolution = ${width}x${height}, Position = ($x, $y)$isPrimary"
    
    # Update total width and height
    $totalWidth += $width
    $totalHeight = [math]::Max($totalHeight, $height)  # Get the maximum height
}

# Output the total resolution
Write-Host "Total Resolution: ${totalWidth}x${totalHeight}"
