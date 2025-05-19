$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
$strUsername = $strActiveUser.Split('\')[1]
$tempPath = "C:\Users\$strUsername\AppData\Local\Temp"

$items = Get-ChildItem -Path $tempPath -Recurse -Force

foreach ($item in $items) {
    try {
        Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction Stop
        Write-Host "Deleted: $($item.FullName)"
    } catch {
        Write-Host "Failed to delete: $($item.FullName) - $_"
    }
}

Write-Host "Temporary files cleanup attempt completed for: $tempPath"