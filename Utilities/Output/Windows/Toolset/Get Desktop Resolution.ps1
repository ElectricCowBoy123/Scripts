Add-Type -AssemblyName System.Windows.Forms

function funcGetDesktopResolution {
    $objScreen = [System.Windows.Forms.Screen]::PrimaryScreen
    return "{0}x{1}" -f $objScreen.Bounds.Width, $objScreen.Bounds.Height
}

$strCurrentResolution = funcGetDesktopResolution
Write-Host "[Informational] Current desktop resolution: $strCurrentResolution"