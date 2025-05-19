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

$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value

#region Variable Declarations
# Name of Software to be Installed.
$strSoftwareName = "Adobe Reader"

# Download URL.
$strDownloadURL = "http://SOMETHING.net/ninja/software/adobereaderdc/AdobeReaderDC.zip"

# Installer MSI temp folder location.
$strFolderPath = "$env:TEMP\TEST"

# Installer CMD file location.
#$strDestinationPath = "$strFolderPath/install.cmd"
$strarrRegDisplayName = @("Adobe Acrobat (64-bit)")
#endregion

#region Check If Already Installed

$strarruninstallKeys = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

try {
    $boolInstalled = Get-InstallStatus -UninstallKeys $strarruninstallKeys -RegDisplayNames $strarrRegDisplayName -OutputStatus $False
}
catch {
    throw "Failed to Get Current Installation Status $($_.Exception)"
}

if($boolInstalled){
    Write-Host "Adobe Reader DC is Already Installed!"
    Exit 0
}

# If not installed, check for required folder path and create if required.
if(!(Test-Path -Path $strFolderPath)){
      New-Item -ItemType Directory -Path $strFolderPath -Force -Confirm:$False
}

# Check if a previous attempt failed, leaving the installer in the temp directory and breaking the script. If so, remove existing installer and re-download.
if (Test-Path -Path $strFolderPath) {
   Remove-Item $strFolderPath -Force -ErrorAction SilentlyContinue -Recurse -Include *.*
   Write-Host "[Informational] Removed $strFolderPath..."
}
#endregion

#region Download Software
try {
    Write-Host "[Informational] Beginning download of $strSoftwareName to $strFolderPath\$strSoftwareName.zip"
    Invoke-WebRequest -Uri $strDownloadURL -OutFile "$strFolderPath/$strSoftwareName.zip"
} catch {
    throw "[Error] Error Downloading - $($_.Exception.Response.StatusCode.value_) Exception: $_"
}

# Extract Archive
try {
    Expand-Archive "$strFolderPath\$strSoftwareName.zip" -DestinationPath $strFolderPath -Force -Confirm:$False
}
catch {
    throw "[Error] Error Expanding Archive"
}
finally {
    # Delete Archive
    try {
        Remove-Item -Path "$strFolderPath\$strSoftwareName.zip" -Force -Confirm:$False
    }
    catch {
        throw "[Error] Error Removing Archive"
    }
}
#endregion

#Region Begin Install
# Start the install
Write-Host "[Informational] Initiating install of $strSoftwareName..."
try {
    # Execute the batch file
    #Start-Process -FilePath $strDestinationPath -NoNewWindow -Wait # error indicates issue with AcroRdrDCUpd2300320201.msp
    Start-Process msiexec -ArgumentList "/i `"$strFolderPath\AcroRead.msi`" ALLUSERS=1 /qn TRANSFORMS=`"$strFolderPath\AcroRead.mst`" /Update `"$strFolderPath\AcroRdrDCUpd2300320201.msp`" /norestart /L*V `"$strFolderPath\AcroRead.log`""
    #msiexec /i "%~dp0AcroRead.msi" ALLUSERS=1 /qn TRANSFORMS="AcroRead.mst" /Update "%~dp0AcroRdrDCUpd2300320201.msp" /norestart
}
catch{
    throw "[Error] Error occured during install"
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