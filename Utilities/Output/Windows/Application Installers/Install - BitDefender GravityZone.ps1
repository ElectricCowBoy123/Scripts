function Get-InstallStatus {
    param (
        [Parameter(Mandatory = $True)]
        $UninstallKeys,
        $RegDisplayNames,
        [bool]$OutputStatus
    )

    $maxChecks = 10
    $checkInterval = 30  # in seconds
    $currentCheck = 0

    while ($currentCheck -lt $maxChecks) {
        Start-Sleep -Seconds $checkInterval
        $currentCheck++
        if($OutputStatus){
            Write-Host "[Informational] Checking installation status... (Attempt $currentCheck of $maxChecks)"
        }
        $installed = $false
        foreach ($key in $UninstallKeys) {
            foreach ($objRegKey in Get-ItemProperty $key -ErrorAction SilentlyContinue) {
                foreach ($strRegDisplayName in $RegDisplayNames) {
                    if ($objRegKey.DisplayName -eq $strRegDisplayName) {
                        $installed = $true
                        break
                    }
                }
                if ($installed) { break }
            }
            if ($installed) { break }
        }
        if ($installed) { break }
    }
    return $installed
}

#region Variable Declarations
# Name of Software to be Installed.
$strSoftwareName = "Bitdefender"
# Uninstaller Display Name.
$strarrRegDisplayName = @("Bitdefender Endpoint Security Tools")
# Download URL.
#$strDownloadURL = "https://download.bitdefender.com/SMB/Hydra/release/bst_win/downloaderWrapper/BEST_downloaderWrapper.msi?_gl=1*boehrw*_ga*NjE4MDM3NjEwLjE3MTA0NTg2OTQ.*_ga_6M0GWNLLWF*MTcxMDQ1ODcyOS4xLjEuMTcxMDQ1ODg0Ny41My4wLjA."
$strDownloadURL = "https://download.bitdefender.com/SMB/Hydra/release/bst_win/downloaderWrapper/BEST_downloaderWrapper.msi?adobe_mc=MCORGID%3D0E920C0F53DA9E9B0A490D45%2540AdobeOrg%7CTS%3D1722603300&_gl=1*g5ehzw*_ga*MTA5OTc4MTQ3NS4xNzIyNjAzMzIw*_ga_6M0GWNLLWF*MTcyMjYwMzMxOS4xLjAuMTcyMjYwMzMyNy41Ny4wLjE3NTY2MzgwNDI."
# Installer MSI temp folder location.
$strFolderPath = "$env:TEMP\DIR"
# Installer MSI file name.
$strInstallerFileName = "BEST_downloaderWrapper.msi"
# Installer MSI file location.
$strDestinationPath = "$strFolderPath\$strInstallerFileName"
# Check if it's already installed.
#endregion

$strarruninstallKeys = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

#region Check If Already Installed
try {
    $boolInstalled = Get-InstallStatus -UninstallKeys $strarruninstallKeys -RegDisplayNames $strarrRegDisplayName -OutputStatus $False
}
catch {
    throw "Failed to Get Current Installation Status $($_.Exception)"
}

if($boolInstalled){
    Write-Host "BitDefender is Already Installed!"
    Exit 0
}

# If not installed, check for required folder path and create if required.
if(!(Test-Path -Path $strFolderPath)){
      New-Item -ItemType Directory -Path $strFolderPath
}

# Check if a previous attempt failed, leaving the installer in the temp directory and breaking the script. If so, remove existing installer and re-download.
if (Test-Path -Path $strFolderPath) {
   Remove-Item $strFolderPath -Force -ErrorAction SilentlyContinue -Recurse -Include *.*
   Write-Host "[Informational] Removed $strFolderPath..."
}
#endregion

#region Download Software
try {
    Write-Host "[Informational] Beginning download of $strSoftwareName to $strFolderPath/$strInstallerFileName"
    Invoke-WebRequest -Uri $strDownloadURL -OutFile "$strFolderPath/$strInstallerFileName"
} catch {
    throw "[Error] Error Downloading - $($_.Exception.Response.StatusCode.value_) Exception: $($_.Exception)"
}
#endregion

#region Begin Install
# Start the install
Write-Output "[Informational] Initiating install of $strSoftwareName..."
try {
    Start-Process msiexec "/i $strDestinationPath /qn GZ_PACKAGE_ID=$($env:companyhash) REBOOT_IF_NEEDED=0" -wait
} catch {
    throw = " `n
    [Error] Failed to install $strSoftwareName. `n
    [Error] To be sure check for the following 2 reg entries and if present consider increasing time delay in this script. `n
    [Error] HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$strRegDisplayName `n
    [Error] HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$strRegDisplayName `n
    [Error] If not present the installation has failed. Check the log file below for more detials `n
    [Error] Exception Details: $($_.Exception)
    "
}

try {
    $boolInstalled = Get-InstallStatus -UninstallKeys $strarruninstallKeys -RegDisplayNames $strarrRegDisplayName -OutputStatus $True
}
catch {
    throw "Failed to Get Current Installation Status $($_.Exception)"
}

if ($boolInstalled) {
    Remove-Item $strFolderPath -Force -ErrorAction SilentlyContinue -Recurse -Include *.*
    Write-Host "[Informational] Removed $strFolderPath..."
    Write-Host "[Informational] $strSoftwareName successfully installed."
    Exit 0
}
#endregion