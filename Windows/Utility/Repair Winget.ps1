Write-Host "Repairing Winget..."
try {
    Repair-WinGetPackageManager
}
catch {
    throw "Failed to repair Winget!"
}
Write-Host "Winget Repaired Sucessfully"