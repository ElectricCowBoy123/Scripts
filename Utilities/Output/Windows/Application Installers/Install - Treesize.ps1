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

#region Variable Declaration
# Execute the query and retrieve the active user session
$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
# Get the SID (Security Identifier) of the active user
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value

$strRegistryPath = "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Uninstall\TreeSize"
$strDownloadPath = "$($env:SYSTEMDRIVE)\TEST\TreeSize"
$strURL = "https://SOMETHING.net/ninja/software/treesize/treesize_free_4.4.1.512.zip"
$strInstallDir = "$($env:SYSTEMDRIVE)\Program Files (x86)\TreeSize"
$strRegDisplayName = "TreeSize Free 4.4.1.512"
$strSoftwareName = "TreeSize"
#endregion

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

#region Logic
if (-Not(Test-Path $strDownloadPath )) {
    New-Item -Path $strDownloadPath -ItemType Directory | Out-Null
}

try {
    Invoke-WebRequest -Uri $strURL -OutFile "$strDownloadPath\TreeSizeInstall.zip"
}
catch {
    throw "[Error] There was an error downloading TreeSize. $($_.Exception)"
}

try{
    Expand-Archive -Path "$strDownloadPath\TreeSizeInstall.zip" -DestinationPath $strDownloadPath -Force
}
catch{
    throw "[Error] Failed to Unzip $strDownloadPath\TreeSizeInstall.zip $($_.Exception)"
}
if (-Not(Test-Path $strInstallDir )) {
    New-Item -Path $strInstallDir -ItemType Directory | Out-Null
}

$batchContent = @"
@echo off

reg delete "$("HKEY_USERS\$strUserSID")\Software\Microsoft\Windows\CurrentVersion\Uninstall\TreeSize" /f

IF EXIST "$($strInstallDir)" (
    rmdir /S /Q "$($strInstallDir)"
) ELSE (
    echo Directory "$($strInstallDir)" does not exist.
)
"@

try{
    Set-Content -Path "$($strInstallDir)\Uninstall.bat" -Value $batchContent -Force
}
catch{
    throw "[Error] Failed to Create Batchfile $($_.Exception)"
}
try {
    Set-FolderPermissions -User "$strActiveUser" -FolderPath "$strInstallDir" -Permission "FullControl"
}
catch {
    throw "[Error] Failed to Set User Level Permissions on $strInstallDir $($_.Exception)"
}


try{
    Copy-Item -Path "$strDownloadPath\TreeSizeFree-Portable\GlobalOptions.xml" -Destination $strInstallDir -Force
}
catch {
    throw "[Error] Failed Copying GlobalOptions.xml to $strInstallDir $($_.Exception)"
}

try{
    Copy-Item -Path "$strDownloadPath\TreeSizeFree-Portable\RibbonOptions.xml" -Destination $strInstallDir -Force
}
catch {
    throw "[Error] Failed Copying RibbonOptions.xml to $strInstallDir $($_.Exception)"
}

try{
    Copy-Item -Path "$strDownloadPath\TreeSizeFree-Portable\LicenseFiles" -Destination $strInstallDir -Recurse -Force
}
catch {
    throw "[Error] Failed Copying LicenseFiles Dir to $strInstallDir $($_.Exception)"
}

try{
    Copy-Item -Path "$strDownloadPath\TreeSizeFree-Portable\TreeSizeFree.chm" -Destination $strInstallDir -Force
}
catch {
    throw "[Error] Failed Copying TreeSizeFree.chm to $strInstallDir $($_.Exception)"
}

try{
    Copy-Item -Path "$strDownloadPath\TreeSizeFree-Portable\TreeSizeFree.exe" -Destination $strInstallDir -Force
}
catch {
    throw "[Error] Failed Copying TreeSizeFree.exe to $strInstallDir $($_.Exception)"
}

<#
# Uninstaller doesn't remove desktop icons lets leave this out for now

[String]$homeFolder = "$($env:SYSTEMDRIVE)\Users\" + $($strActiveUser -replace '.*\\')

$WshShell = New-Object -comObject WScript.Shell
$objShortcut = $WshShell.CreateShortcut("$homeFolder\Desktop\WinDirStat.lnk")
$objShortcut.TargetPath = "$strInstallDir\windirstat.exe"
$objShortcut.Save()
#>
try {
    $WshShell = New-Object -comObject WScript.Shell
    $objShortcut = $WshShell.CreateShortcut("$($env:SYSTEMDRIVE)\ProgramData\Microsoft\Windows\Start Menu\Programs\TreeSizeFree.lnk")
    $objShortcut.TargetPath = "$strInstallDir\TreeSizeFree.exe"
    $objShortcut.Save()
}
catch {
    throw "[Error] Failed to Create Shortcut $($_.Exception)"
}

if (-not (Test-Path $strRegistryPath)) {
    New-Item -Path $strRegistryPath -Force
}

try{
    New-ItemProperty -Path $strRegistryPath -Name "UninstallString" -PropertyType ExpandString -Value "$strInstallDir\Uninstall.bat" -Force
    New-ItemProperty -Path $strRegistryPath -Name "InstallLocation" -PropertyType ExpandString -Value "$strInstallDir" -Force
    New-ItemProperty -Path $strRegistryPath -Name "DisplayName" -PropertyType String -Value "TreeSize Free 4.4.1.512" -Force
    New-ItemProperty -Path $strRegistryPath -Name "DisplayIcon" -PropertyType String -Value "$strInstallDir\TreeSizeFree.exe,0" -Force
    New-ItemProperty -Path $strRegistryPath -Name "dwVersionMajor" -PropertyType DWord -Value 0x00000001 -Force
    New-ItemProperty -Path $strRegistryPath -Name "dwVersionMinor" -PropertyType DWord -Value 0x00000001 -Force
    New-ItemProperty -Path $strRegistryPath -Name "dwVersionRev" -PropertyType DWord -Value 0x00000002 -Force
    New-ItemProperty -Path $strRegistryPath -Name "dwVersionBuild" -PropertyType DWord -Value 0x0000004f -Force
    New-ItemProperty -Path $strRegistryPath -Name "URLInfoAbout" -PropertyType String -Value "https://https://www.jam-software.com/treesize_free/" -Force
    New-ItemProperty -Path $strRegistryPath -Name "NoModify" -PropertyType DWord -Value 0x00000001 -Force
    New-ItemProperty -Path $strRegistryPath -Name "NoRepair" -PropertyType DWord -Value 0x00000001 -Force
}
catch {
    throw "[Error] Failed to Create Registry Keys $($_.Exception)"
}

try{
    Remove-Item -Path "$strDownloadPath" -Force -Recurse
}
catch{
    throw "[Error] Failed to Remove Download Directory $($_.Exception)"
}

while($True) {
    Start-Sleep -Seconds 10
    
    foreach($objRegKey in $(Get-ItemProperty "$strRegistryPath" -ErrorAction SilentlyContinue)){
        if($objRegKey.DisplayName -eq $strRegDisplayName){
            Remove-Item "$strDownloadPath\TreeSizeInstall.zip" -Force -ErrorAction SilentlyContinue -Recurse -Include *.*
            Write-Host "[Informational] Removed $strDownloadPath\TreeSizeInstall.zip..."
            Remove-Item "$strDownloadPath" -Force -ErrorAction SilentlyContinue -Recurse -Include *.*
            Write-Host "[Informational] Removed $strDownloadPath..."
            Exit 0
        }
    }
    
    foreach($objRegKey in $(Get-ItemProperty "$strRegistryPath" -ErrorAction SilentlyContinue)){
        if($objRegKey.DisplayName -eq $strRegDisplayName){
            Remove-Item "$strDownloadPath\TreeSizeInstall.zip" -Force -ErrorAction SilentlyContinue -Recurse -Include *.*
            Write-Host "[Informational] Removed $strDownloadPath\TreeSizeInstall.zip..."
            Remove-Item "$strDownloadPath" -Force -ErrorAction SilentlyContinue -Recurse -Include *.*
            Write-Host "[Informational] Removed $strDownloadPath..."
            Exit 0
        }
    }
}
#endregion