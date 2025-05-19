# Kill all sessions of hp anywhere
# Remove old version
# Install new version

#region Variable Declarations
# Name of Software to be Installed.
$strSoftwareName = "Anyware PCoIP Client"
# Uninstaller Display Name.
$strRegDisplayName = "Anyware PCoIP Client"
# Download URL.
$strDownloadURL = "\\10.60.1.22\Sources\Applications\Teradici\pcoip-client_24.07.4.exe"
# Installer temp folder location.
$strFolderPath = "$env:TEMP\DIR" #PRIVATE
# Installer file name.
$strInstallerFileName = "pcoip-client_24.07.4.exe"
# Installer file location.
$strDestinationPath = "$strFolderPath\$strInstallerFileName"
# Version to be installed
$strVersion = '24.07.4'  # Update to match the version in the installer
# Process to terminate
$strProcessName = 'pcoip_client'
#endregion

#region Test Server Path
if (-not (Test-Path -Path $strDownloadURL)) {
    Write-Host "Unable to Access Path $strDownloadURL"
    exit 1
}
#endregion

#region Uninstall old version
# Stop the process if it's running
$objProcess = Get-Process -Name $strProcessName -ErrorAction SilentlyContinue
if ($objProcess) {
    Stop-Process -Id $objProcess.Id -Force
    Write-Host "[Informational] Stopped process $strProcessName."
}

# Uninstall old versions
$uninstallKeys = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

foreach ($key in $uninstallKeys) {
    foreach ($objRegKey in Get-ItemProperty $key) {
        if ($objRegKey.DisplayName -eq $strRegDisplayName -and $objRegKey.DisplayVersion -ne $strVersion) {
            Write-Host "[Informational] Uninstalling old version of $strSoftwareName..."
            Start-Process -FilePath $objRegKey.UninstallString -ArgumentList "/s" -Wait
            Write-Host "[Informational] $strSoftwareName uninstalled."
        }
    }
}
#endregion

#region Check If Already Installed
$alreadyInstalled = $false

foreach ($key in $uninstallKeys) {
    foreach ($objRegKey in Get-ItemProperty $key) {
        if ($objRegKey.DisplayName -eq $strRegDisplayName) {
            Write-Host "[Informational] $strSoftwareName is already installed. Exiting."
            exit 1
        }
    }
    if ($alreadyInstalled) { break }
}

# If not installed, check for required folder path and create if required.
if (-not $alreadyInstalled -and -not (Test-Path -Path $strFolderPath)) {
    New-Item -ItemType Directory -Path $strFolderPath | Out-Null
}
#endregion

#region Download Software
try {
    Write-Output "Copying $strSoftwareName to $strDestinationPath"
    Copy-Item -Path $strDownloadURL -Destination $strDestinationPath -ErrorAction Stop
} catch {
    throw "[Error] Error copying: $($_.Exception.Message)"
}
#endregion   

#region Begin Install
try {
    # Start the install
    Write-Output "[Informational] Initiating install of $strSoftwareName..."
    Start-Process -FilePath $strDestinationPath -ArgumentList '/S' -Wait
} catch {
    throw "[Error] Error installing $strSoftwareName $($_.Exception.Message)"
}

# Wait for installation to complete and check if installed
while ($True) {
    Start-Sleep -Seconds 30

    foreach ($key in $uninstallKeys) {
        foreach ($objRegKey in Get-ItemProperty $key) {
            if ($objRegKey.DisplayName -eq $strRegDisplayName) {
                Remove-Item $strFolderPath -Force -Recurse -ErrorAction SilentlyContinue
                Write-Host "[Informational] Removed $strFolderPath..."
                Write-Host "[Informational] $strSoftwareName is now installed."
                Exit 0
            }
        }
    }
}
#endregion
