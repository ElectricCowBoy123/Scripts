Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

function Get-Desktop {
    $bounds = [System.Windows.Forms.Screen]::PrimaryScreen.Bounds
    $bitmap = New-Object System.Drawing.Bitmap $bounds.Width, $bounds.Height
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.CopyFromScreen($bounds.Location, [System.Drawing.Point]::Empty, $bounds.Size)
    $memoryStream = New-Object System.IO.MemoryStream
    $bitmap.Save($memoryStream, [System.Drawing.Imaging.ImageFormat]::Png)
    $byteArray = $memoryStream.ToArray()
    $base64String = [Convert]::ToBase64String($byteArray)
    $graphics.Dispose()
    $bitmap.Dispose()
    $memoryStream.Dispose()
    return $base64String
}

$Base64 = Get-Desktop
Write-Output $Base64
