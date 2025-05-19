$currentVersion = $PSVersionTable.PSVersion
Write-Host "Current Powershell Version: $currentVersion"

$downloadUrl = "https://download.microsoft.com/download/6/F/5/6F5FF66C-6775-42B0-86C4-47D41F2DA187/W2K12-KB3191565-x64.msu"

$installerPath = "$($env:TEMP)\W2K12-KB3191565-x64.msu"

if ($currentVersion.Major -lt 5 -or ($currentVersion.Major -eq 5 -and $currentVersion.Minor -lt 1)) {
    Write-Host "Updating Powershell to version 5.1..."
    
    $webClient = New-Object System.Net.WebClient

    $webClient.DownloadFile($downloadUrl, $installerPath)

    Start-Process -FilePath "wusa.exe" -ArgumentList "$installerPath /quiet /norestart" -Wait

    Write-Host "PowerShell 5.1 installation completed. Restart the machine."
} else {
    Write-Host "You already have PowerShell 5.1"
}
