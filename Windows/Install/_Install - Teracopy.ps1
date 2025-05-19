function Set-FolderPermissions {
    param (
        [string]$User,        
        [string]$FolderPath,  
        [string]$Permission
    )

    $acl = Get-Acl $FolderPath
    $accessRule = New-Object System.Security.AccessControl.FileSystemAccessRule($User, $Permission, "ContainerInherit,ObjectInherit", "None", "Allow")
    $acl.AddAccessRule($accessRule)
    Set-Acl -Path $FolderPath -AclObject $acl
}

#region Variable Declarations
# Name of Software to be Installed.
$strSoftwareName = "TeraCopy"
# Uninstaller Display Name.
$strRegDisplayName = "TeraCopy"
# Download URL.
$strDownloadURL = "https://www.codesector.com/files/teracopy.exe"
# Installer MSI temp folder location.
$strFolderPath = "$($env:SYSTEMDRIVE)\TEST" #PRIVATE
# Installer MSI file name.
$strInstallerFileName = "teracopy.exe"
# Installer MSI file location.
$strDestinationPath = "$strFolderPath\$strInstallerFileName"

$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
# Get the SID (Security Identifier) of the active user
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value

$strRegistryPath = "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Uninstall\TeraCopy"
#endregion

#region Check If Already Installed
foreach($objRegKey in $(Get-ItemProperty "$strRegistryPath" -ErrorAction SilentlyContinue)){
    if($objRegKey.DisplayName -eq $strRegDisplayName){
        Write-Host "[Informational] $strSoftwareName x32 already installed. Exiting."
        Exit 0
    }
}

foreach($objRegKey in $(Get-ItemProperty "$strRegistryPath" -ErrorAction SilentlyContinue)){
    if($objRegKey.DisplayName -eq $strRegDisplayName){
        Write-Host "[Informational] $strSoftwareName x64 already installed. Exiting."
        Exit 0
    }
}

# Check if a previous attempt failed, leaving the installer in the temp directory and breaking the script. If so, remove existing installer and re-download.
if (Test-Path -Path "$strFolderPath\TeraCopy") {
    Remove-Item "$strFolderPath\TeraCopy" -Force -ErrorAction SilentlyContinue -Recurse -Include *.*
    Write-Host "[Informational] Removed $strFolderPath\TeraCopy..."
}

# If not installed, check for required folder path and create if required.
if (-not (Test-Path -Path "$strFolderPath\TeraCopy")) {
    New-Item -ItemType Directory -Path "$strFolderPath\TeraCopy"
    Write-Host "[Informational] Removed $strFolderPath\TeraCopy..."
}

if (-not (Test-Path -Path "$($env:SYSTEMDRIVE)\Program Files\Teracopy")) {
    New-Item -ItemType Directory -Path "$($env:SYSTEMDRIVE)\Program Files\TeraCopy"
    Write-Host "[Informational] Removed $($env:SYSTEMDRIVE)\Program Files\TeraCopy..."
}

#endregion

#region Download Software
try {
    Write-Output "Beginning download of $strSoftwareName to $strDestinationPath"
    Invoke-WebRequest -Uri $strDownloadURL -OutFile $strDestinationPath
} catch {
    throw "[Error] Error Downloading - $($_.Exception.Response.StatusCode.value_)"
}
#endregion  
 
#region Begin Install
try {
    Write-Output "[Informational] Extracting MSI for $strSoftwareName..."
    Start-Process -FilePath "$strDestinationPath" -ArgumentList "/extract `"$strFolderPath\TeraCopy`"" -Wait -NoNewWindow
    $subDir = Get-ChildItem -Directory "$strFolderPath\TeraCopy" | Select-Object -First 1
    Write-Host "$strFolderPath\TeraCopy\$subDir\"
    Copy-Item -Path "$strFolderPath\TeraCopy\$subDir\*" -Destination "$($env:SYSTEMDRIVE)\Program Files\TeraCopy" -Recurse -Force
} catch {
    throw "[Error] Error Extracting $strSoftwareName Exception: $($_.Exception)"
}

$batchContent = @"
@echo off

reg delete "$("HKEY_USERS\$strUserSID")\Software\Microsoft\Windows\CurrentVersion\Uninstall\TeraCopy" /f

IF EXIST "$($env:SYSTEMDRIVE)\Program Files\TeraCopy" (
    rmdir /S /Q "$($env:SYSTEMDRIVE)\Program Files\TeraCopy"
) ELSE (
    echo Directory "$($env:SYSTEMDRIVE)\Program Files\TeraCopy" does not exist.
)
"@

try{
    Set-Content -Path "$($env:SYSTEMDRIVE)\Program Files\TeraCopy\Uninstall.bat" -Value $batchContent -Force
}
catch{
    throw "[Error] Failed to Create Batchfile $($_.Exception)"
}
try {
    Set-FolderPermissions -User "$strActiveUser" -FolderPath "$($env:SYSTEMDRIVE)\Program Files\TeraCopy" -Permission "FullControl"
}
catch {
    throw "[Error] Failed to Set User Level Permissions on $($env:SYSTEMDRIVE)\Program Files\TeraCopy $($_.Exception)"
}

try {
    $WshShell = New-Object -comObject WScript.Shell
    $objShortcut = $WshShell.CreateShortcut("$($env:SYSTEMDRIVE)\ProgramData\Microsoft\Windows\Start Menu\Programs\TeraCopy.lnk")
    $objShortcut.TargetPath = "$($env:SYSTEMDRIVE)\Program Files\TeraCopy\TeraCopy.exe"
    $objShortcut.Save()
}
catch {
    throw "[Error] Failed to Create Shortcut $($_.Exception)"
}

if (-not (Test-Path $strRegistryPath)) {
    New-Item -Path $strRegistryPath -Force
}

try{
    New-ItemProperty -Path $strRegistryPath -Name "UninstallString" -PropertyType ExpandString -Value "$($env:SYSTEMDRIVE)\Program Files\TeraCopy\Uninstall.bat" -Force
    New-ItemProperty -Path $strRegistryPath -Name "InstallLocation" -PropertyType ExpandString -Value "$($env:SYSTEMDRIVE)\Program Files\TeraCopy" -Force
    New-ItemProperty -Path $strRegistryPath -Name "DisplayName" -PropertyType String -Value "TeraCopy" -Force
    New-ItemProperty -Path $strRegistryPath -Name "DisplayIcon" -PropertyType String -Value "$($env:SYSTEMDRIVE)\Program Files\TeraCopy\TeraCopy.exe,0" -Force
    New-ItemProperty -Path $strRegistryPath -Name "dwVersionMajor" -PropertyType DWord -Value 0x00000001 -Force
    New-ItemProperty -Path $strRegistryPath -Name "dwVersionMinor" -PropertyType DWord -Value 0x00000001 -Force
    New-ItemProperty -Path $strRegistryPath -Name "dwVersionRev" -PropertyType DWord -Value 0x00000002 -Force
    New-ItemProperty -Path $strRegistryPath -Name "dwVersionBuild" -PropertyType DWord -Value 0x0000004f -Force
    New-ItemProperty -Path $strRegistryPath -Name "URLInfoAbout" -PropertyType String -Value "https://www.codesector.com/teracopy/" -Force
    New-ItemProperty -Path $strRegistryPath -Name "NoModify" -PropertyType DWord -Value 0x00000001 -Force
    New-ItemProperty -Path $strRegistryPath -Name "NoRepair" -PropertyType DWord -Value 0x00000001 -Force
}
catch {
    throw "[Error] Failed to Create Registry Keys $($_.Exception)"
}

while($True) {
    Start-Sleep -Seconds 10
    
    foreach($objRegKey in $(Get-ItemProperty "$strRegistryPath" -ErrorAction SilentlyContinue)){
        if($objRegKey.DisplayName -eq $strRegDisplayName){
            Remove-Item "$strDestinationPath" -Force -ErrorAction SilentlyContinue -Recurse -Include *.*
            Write-Host "[Informational] Removed $strDestinationPath..."
            Remove-Item "$strDestinationPath\TeraCopy" -Force -ErrorAction SilentlyContinue -Recurse -Include *.*
            Write-Host "[Informational] Removed $strDestinationPath\TeraCopy..."
            Exit 0
        }
    }
    
    foreach($objRegKey in $(Get-ItemProperty "$strRegistryPath" -ErrorAction SilentlyContinue)){
        if($objRegKey.DisplayName -eq $strRegDisplayName){
            Remove-Item "$strDestinationPath" -Force -ErrorAction SilentlyContinue -Recurse -Include *.*
            Write-Host "[Informational] Removed $strDestinationPath..."
            Remove-Item "$strDestinationPath\TeraCopy" -Force -ErrorAction SilentlyContinue -Recurse -Include *.*
            Write-Host "[Informational] Removed $strDestinationPath\TeraCopy..."
            Exit 0
        }
    }
}
#endregion