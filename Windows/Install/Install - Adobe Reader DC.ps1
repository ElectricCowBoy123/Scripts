$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value

#region Variable Declarations
# Name of Software to be Installed.
$strSoftwareName = "Adobe Reader"

# Download URL.
$strDownloadURL = "http://SOMETHING.net/ninja/software/adobereaderdc/AdobeReaderDC.zip" #PRIVATE

# Installer MSI temp folder location.
$strFolderPath = "$env:TEMP\DIR" #PRIVATE

# Installer CMD file location.
#$strDestinationPath = "$strFolderPath/install.cmd"
$strRegDisplayName = "Adobe Acrobat"
#endregion

#region Check If Already Installed

foreach($objRegKey in $(Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*")){
    if($objRegKey.DisplayName -like "$strRegDisplayName*"){
        Write-Host "[Informational] $strSoftwareName x32 already installed. Exiting."
        Exit 0
    }
}

foreach($objRegKey in $(Get-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")){
    if($objRegKey.DisplayName -like "$strRegDisplayName*"){
        Write-Host "[Informational] $strSoftwareName x64 already installed. Exiting."
        Exit 0
    }
}

foreach($objRegKey in $(Get-ItemProperty "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Uninstall\*")){
    if($objRegKey.DisplayName -like "$strRegDisplayName*"){
        Write-Host "[Informational] $strSoftwareName x64 already installed. Exiting."
        Exit 0
    }
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

while($True) {
    Start-Sleep -Seconds 30

    foreach($objRegKey in $(Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*")){
        if($objRegKey.DisplayName -like "$strRegDisplayName*"){
            Remove-Item $strFolderPath -Force -ErrorAction SilentlyContinue -Recurse -Include *.*
            Write-Host "[Informational] Removed $strFolderPath..."
            Write-Host "[Informational] $strSoftwareName x32 already installed. Exiting."
            Exit 0
        }
    }
    
    foreach($objRegKey in $(Get-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")){
        if($objRegKey.DisplayName -like "$strRegDisplayName*"){
            Remove-Item $strFolderPath -Force -ErrorAction SilentlyContinue -Recurse -Include *.*
            Write-Host "[Informational] Removed $strFolderPath..."
            Write-Host "[Informational] $strSoftwareName x64 already installed. Exiting."
            Exit 0
        }
    }

    foreach($objRegKey in $(Get-ItemProperty "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Uninstall\*")){
        if($objRegKey.DisplayName -like "$strRegDisplayName*"){
            Remove-Item $strFolderPath -Force -ErrorAction SilentlyContinue -Recurse -Include *.*
            Write-Host "[Informational] Removed $strFolderPath..."
            Write-Host "[Informational] $strSoftwareName x64 already installed. Exiting."
            Exit 0
        }
    }
}

#endregion