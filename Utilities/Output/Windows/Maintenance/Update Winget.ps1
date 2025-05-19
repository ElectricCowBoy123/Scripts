$targetVersion = [version]"1.9.25180"
$strDownloadURL = "https://github.com/microsoft/winget-cli/releases/download/$($targetVersion.ToString())/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"
$msixBundlePath = "$($env:USERPROFILE)\Downloads\Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle"

$wingetVersion = winget --version
if ($wingetVersion -like "v*") {
    $wingetVersion = $wingetVersion.Substring(1)
}
$currentVersion = [version]$wingetVersion
if ($currentVersion -ge $targetVersion) {
    throw "[Error] No Update Needed. Version is $currentVersion"
}

if (-not (Test-Path $msixBundlePath)) {
    Invoke-WebRequest -Uri $strDownloadURL -OutFile $msixBundlePath
}
if (Test-Path $msixBundlePath) {
    try {
        Add-AppxPackage -Path $msixBundlePath
        Write-Host "Installation of $msixBundlePath Completed successfully."
        Remove-Item -Path $msixBundlePath -Force -Confirm:$False
    } catch {
        throw "[Error] An error occurred during installation: $($_.Exception.Message)"
    }
} else {
    Write-Host "The specified file does not exist: $msixBundlePath"
}