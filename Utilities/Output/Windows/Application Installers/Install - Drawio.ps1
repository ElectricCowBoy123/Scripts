#region Variable Declarations
$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName

# Name of Software to be Installed.
$strSoftwareName = "draw.io 24.7.17"
# Uninstaller Display Name.
$strRegDisplayName = "draw.io 24.7.17"
# Download URL.
$strDownloadURL = "https://github.com/jgraph/drawio-desktop/releases/download/v24.7.17/draw.io-24.7.17.msi"
# Installer MSI temp folder location.
$strFolderPath = "$env:TEMP\DIR"
# Installer MSI file name.
$strInstallerFileName = "draw.io-24.7.17.msi"
# Installer MSI file location.
$strDestinationPath = "$strFolderPath\$strInstallerFileName"
# Check if it's already installed.
$boolIsInstalled32 = $False
$boolIsInstalled64 = $False
#endregion

#region Validation
foreach($objRegKey in $(Get-ItemProperty "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*")) {
    if($objRegKey.DisplayName -eq $strRegDisplayName) {
        $boolIsInstalled32 = $True
    }
}

foreach($objRegKey in $(Get-ItemProperty "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*")) {
    if($objRegKey.DisplayName -eq $strRegDisplayName) {
        $boolIsInstalled64 = $True
    }
}

# If it's already installed, just do nothing.
if ($boolIsInstalled32) {
    Write-Output "[Informational] $strSoftwareName already installed. Exiting."
    Exit 0
}
if ($boolIsInstalled64) {
    Write-Output "[Informational] $strSoftwareName already installed. Exiting."
    Exit 0
}

if(Test-Path -Path "$strFolderPath"){
    Remove-Item -Path "$strFolderPath"
}
New-Item -ItemType Directory -Path $strFolderPath

# Check if a previous attempt failed, leaving the installer in the temp directory and breaking the script. If so, remove existing installer and re-download.
if (Test-Path $strDestinationPath) {
   Remove-Item $strDestinationPath
   Write-Output "[Informational] Removed $strDestinationPath..."
}
#endregion

#region Logic
try {
    Write-Output "[Informational] Beginning download of $strSoftwareName to $strDestinationPath"
    Invoke-WebRequest -Uri $strDownloadURL -OutFile $strDestinationPath
} catch {
    Write-Output "[Error] Error Downloading - $_.Exception.Response.StatusCode.value_"
    Write-Output $_
    Exit 1
}

#region Extract MSI Contents
Write-Host "[Informational] Extracting Contents of MSI '$strDestinationPath'"
try {
    if(Test-Path -Path "$strFolderPath\Folder"){
        Remove-Item -Path "$strFolderPath\Folder" -Force
    }
    New-Item -Path "$strFolderPath\Folder" -ItemType Directory -Force
    Start-Process msiexec -ArgumentList "/a `"$strDestinationPath`" /qn TARGETDIR=`"$strFolderPath\Folder`"" -Wait
}
catch {
    throw "[Error] Failed to Extract Contents of MSI '$strDestinationPath' $($_.Exception)"
}
#endregion

#region Move MSI Contents to Relevant Directories
Write-Host "[Informational] Moving Contents of MSI to Installdir '$($env:SYSTEMDRIVE)\Program Files'"
try {
    Move-Item -Path "$StrFolderPath\Folder\draw.io" -Destination "$($env:SYSTEMDRIVE)\Program Files" -Force
}
catch {
    throw "[Error] Failed to Move Contents of MSI to Installdir '$($env:SYSTEMDRIVE)\Program Files' $($_.Exception)"
}
#endregion

#region Register the Install
try {
    if (-not (Test-Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\27a75bf3-be48-5c35-934f-8491cf108abe")) {
        New-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\27a75bf3-be48-5c35-934f-8491cf108abe" -Force
    }
    New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\27a75bf3-be48-5c35-934f-8491cf108abe" -Name 'DisplayName' -PropertyType 'String' -Value "draw.io 24.7.17" -ErrorAction SilentlyContinue
    New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\27a75bf3-be48-5c35-934f-8491cf108abe" -Name 'UninstallString' -PropertyType 'String' -Value "$($env:SYSTEMDRIVE)\Program Files\draw.io\Uninstall.bat" -ErrorAction SilentlyContinue
    New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\27a75bf3-be48-5c35-934f-8491cf108abe" -Name 'QuietUninstallString' -PropertyType 'String' -Value "$($env:SYSTEMDRIVE)\Program Files\draw.io\Uninstall.bat" -ErrorAction SilentlyContinue
    New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\27a75bf3-be48-5c35-934f-8491cf108abe" -Name 'DisplayVersion' -PropertyType 'String' -Value "24.7.17" -ErrorAction SilentlyContinue
    New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\27a75bf3-be48-5c35-934f-8491cf108abe" -Name 'DisplayIcon' -PropertyType 'String' -Value "$($env:SYSTEMDRIVE)\Program Files\draw.io\draw.io.exe,0" -ErrorAction SilentlyContinue
    New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\27a75bf3-be48-5c35-934f-8491cf108abe" -Name 'Publisher' -PropertyType 'String' -Value "JGraph" -ErrorAction SilentlyContinue
    New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\27a75bf3-be48-5c35-934f-8491cf108abe" -Name 'NoModify' -PropertyType 'Dword' -Value 1 -ErrorAction SilentlyContinue
    New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\27a75bf3-be48-5c35-934f-8491cf108abe" -Name 'NoRepair' -PropertyType 'Dword' -Value 1 -ErrorAction SilentlyContinue
    New-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\27a75bf3-be48-5c35-934f-8491cf108abe" -Name 'EstimatedSize' -PropertyType 'Dword' -Value 5965 -ErrorAction SilentlyContinue
}   
catch {
    throw "[Error] Failed to Register the Installation $($_.Exception)"
}
#endregion
#region Create Start Menu Shortcut
try {
    $shortcutName = "Draw.io.lnk"
    $targetPath = "$($env:SYSTEMDRIVE)\Program Files\draw.io\draw.io.exe"  # Change this to the target file or folder
    $shortcutLocation = "$($env:SYSTEMDRIVE)\Users\$(($strActiveUser -split '\\')[1])\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\$shortcutName"
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutLocation)
    $shortcut.TargetPath = $targetPath
    $shortcut.WorkingDirectory = [System.IO.Path]::GetDirectoryName($targetPath)
    $shortcut.IconLocation = $targetPath  # Optional: Set the icon to the target's icon
    $shortcut.Save()
}
catch {
    throw "[Error] Failed to Create Start Menu Shortcut! $($_.Exception)" 
}
#endregion

#region Create Custom Uninstallation Script
try {
    $strCustomUninstallString = @"
@echo off
rmdir /s /q "$($env:SYSTEMDRIVE)\Program Files\draw.io"
reg delete "HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\27a75bf3-be48-5c35-934f-8491cf108abe" /f
"@
    Set-Content -Path "$($env:SYSTEMDRIVE)\Program Files\draw.io\Uninstall.bat" -Value $strCustomUninstallString
}
catch {
    throw "[Error] Failed to Create Uninstall.bat! $($_.Exception)" 
}
#endregion

Write-Host "Install Successful!"

if(Test-Path -Path "$strFolderPath"){
    Remove-Item -Path "$strFolderPath"
}