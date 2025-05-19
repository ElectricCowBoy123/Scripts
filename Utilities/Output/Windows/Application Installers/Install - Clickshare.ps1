
$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
Write-Host "User SID: $($strUserSID)"
Write-Host "Active User: $($strActiveUser)"
#region Variable Declarations
# Name of Software to be Installed.
$strSoftwareName = "ClickShare"
# Uninstaller Display Name.
$strarrRegDisplayName = @("ClickShare App-based Conferencing Drivers","ClickShare","ClickShare Desktop App Machine-Wide Installer")
# Download URL.
$strDownloadURL = "https://www.barco.com/bin/barco/tde/downloadUrl.json?fileNumber=R3306194&tdeType=3"
# Installer MSI temp folder location.
$strFolderPath = "$env:TEMP\DIR"
# Installer zip file name.
$strInstallerZipFileName = "Clickshare.zip"
# Installer MSI file name.
$strInstallerFileName = "ClickShare_Installer.msi"
# Installer zip file location.
$strDestinationPath = "$strFolderPath\$strInstallerZipFileName"
# Installer MSI file location after extract.
$strInstallerPath = "$strFolderPath\$strInstallerFileName"
#endregion

$uninstallKeys = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

#region Check If Already Installed

foreach ($key in $uninstallKeys) {
    foreach($objRegKey in $(Get-ItemProperty $key)){
        foreach($strRegDisplayName in $strarrRegDisplayName){
            if($objRegKey.DisplayName -eq $strRegDisplayName){
                Write-Host "[Informational] $strSoftwareName already installed. Exiting."
                Exit 0
            }
        }
    }
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

#region Pull Download URL from Barco Webservice
try {
    $objResponse = Invoke-WebRequest -Uri $strDownloadURL -UseBasicParsing
    $jsonData = $objResponse.Content | ConvertFrom-Json
    if($(($jsonData.downloadUrl).ToString()).Length -gt 0){
        $strDownloadURL = $($jsonData.downloadUrl).ToString()
    }
    else {
        throw "[Error] Failed to Retrieve Download URL from Barco Webservice $($_.Exception)"
    }
}
catch {
    throw "[Error] Failed to Call the Barco Webservice $($_.Exception)"
}

#endregion


#region Download Software
try {
    Write-Output "Beginning download of $strSoftwareName to $strDestinationPath"
    Invoke-WebRequest -Uri $strDownloadURL -OutFile $strDestinationPath -UseBasicParsing
} catch {
    throw "[Error] Error Downloading - $($_.Exception.Response.StatusCode.value_)"
}
#endregion   

#region Extract Software
try {
    Write-Output "Beginning Extract of $strDestinationPath"
    Expand-Archive -Path "$strDestinationPath" -DestinationPath "$strFolderPath"
} catch {
    throw "[Error] Error Extracting - $($_.Exception)"
}
#endregion  

#region Begin Install
try {
    # Start the install
    Write-Output "[Informational] Initiating install of $strSoftwareName..."
    Start-Process msiexec -ArgumentList "/i `"$strInstallerPath`" /qn /norestart /l*v `"$strFolderPath\clickshare_install.log`" REBOOT=REALLYSUPPRESS ACCEPT_EULA=YES APP_BASED_CONFERENCING=YES USER_EXP=SA APPDATA=`"$($env:SYSTEMDRIVE)\Users\$(($strActiveUser -split '\\')[1])\AppData\Roaming`" USERPROFILE=`"$($env:SYSTEMDRIVE)\Users\$(($strActiveUser -split '\\')[1])`" LOCALAPPDATA=`"$($env:SYSTEMDRIVE)\Users\$(($strActiveUser -split '\\')[1])\AppData\Local`"" -Wait -Verb RunAs
} catch {
    throw "[Error] Error installing $strSoftwareName Exception: $($_.Exception)"
}
# Define maximum number of checks and interval
$maxChecks = 10
$checkInterval = 30  # in seconds
$currentCheck = 0

while ($currentCheck -lt $maxChecks) {
    Start-Sleep -Seconds $checkInterval
    $currentCheck++

    Write-Host "[Informational] Checking installation status... (Attempt $currentCheck of $maxChecks)"

    $installed = $false

    foreach ($key in $uninstallKeys) {
        foreach ($objRegKey in Get-ItemProperty $key -ErrorAction SilentlyContinue) {
            foreach ($strRegDisplayName in $strarrRegDisplayName) {
                if ($objRegKey.DisplayName -eq $strRegDisplayName) {
                    $installed = $true
                    break
                }
            }
            if ($installed) { break }
        }
        if ($installed) { break }
    }

    if ($installed) {
        Remove-Item $strFolderPath -Force -ErrorAction SilentlyContinue -Recurse -Include *.*
        Write-Host "[Informational] Removed $strFolderPath..."
        Write-Host "[Informational] $strSoftwareName successfully installed."
        Exit 0
    }
}

Write-Host "[Error] $strSoftwareName installation not detected after $maxChecks attempts."
#endregion