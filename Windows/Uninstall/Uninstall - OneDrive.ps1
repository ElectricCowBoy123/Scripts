New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null

$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
$strUsername = $strActiveUser.Split('\')[1]

# Create Required Registry Keys if they don't Exist (Prevents a Potential Installer Bug)
try {
    if (-not (Test-Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}")) {
        New-Item -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Force
    }
    if (-not (Test-Path "HKCR:\Wow6432Node\CLSID{018D5C66-4533-4307-9B53-224DE2ED1FE6}")) {
        New-Item -Path "HKCR:\Wow6432Node\CLSID{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Force
    }
}
catch {
    throw "Failed to Create Required Uninstaller Registry Keys! $($_.Exception)"
}

# Kill OneDrive
try {
    taskkill.exe /F /IM "OneDrive.exe"
}
catch {
    throw "Failed to kill OneDrive! $($_.Exception)"
}

# Execute the Uninstaller
try {
    if (Test-Path "$env:SYSTEMROOT\System32\OneDriveSetup.exe") {
        & "$env:SYSTEMROOT\System32\OneDriveSetup.exe" /uninstall
    }
    if (Test-Path "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe") {
        & "$env:SYSTEMROOT\SysWOW64\OneDriveSetup.exe" /uninstall
    }
}
catch {
    throw "Failed to Execute OneDrive Uninstaller $($_.Exception)"
}

# Remove Temp, AppData and ProgramData OneDrive Directories
try {
    if(Test-Path -Path "$env:SYSTEMDRIVE\Users\$strUsername\AppData\Local\Microsoft\OneDrive"){
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:SYSTEMDRIVE\Users\$strUsername\AppData\Local\Microsoft\OneDrive"
    }
    if(Test-Path -Path "$env:PROGRAMDATA\Microsoft OneDrive"){
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:PROGRAMDATA\Microsoft OneDrive"
    }
    if(Test-Path -Path "$env:SYSTEMDRIVE\OneDriveTemp"){
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:SYSTEMDRIVE\OneDriveTemp"
    }

    # Check if the Directory is Empty Before Removing (OneDrive User Directory)
    if ((Get-ChildItem "$env:SYSTEMDRIVE\Users\$strUsername\OneDrive" -Recurse | Measure-Object).Count -eq 0){
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue "$env:SYSTEMDRIVE\Users\$strUsername\OneDrive"
    }
}
catch {
    throw "Failed to Remove One or More OneDrive Related Directories! $($_.Exception)"
}

# Remove Shell Integration Registry Keys
try {
    Set-ItemProperty -Path "HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name System.IsPinnedToNameSpaceTree -Value 0 -Type DWord -Force
    Set-ItemProperty -Path "HKCR:\Wow6432Node\CLSID{018D5C66-4533-4307-9B53-224DE2ED1FE6}" -Name System.IsPinnedToNameSpaceTree -Value 0 -Type DWord -Force
}
catch {
    throw "Failed to Remove Shell Integration Registry Keys! $($_.Exception)"
}

# Remove Startmenu Entry
try {
    Remove-Item -Force -ErrorAction SilentlyContinue "$env:SYSTEMDRIVE\Users\$strUsername\AppData\Roaming\Microsoft\Windows\Start Menu\Programs\OneDrive.lnk"
}
catch {
    throw "Failed to OneDrive Related Startmenu Entries! $($_.Exception)"
}

# Remove any OneDrive Scheduled Tasks
try {
    Get-ScheduledTask -TaskPath '\' -TaskName 'OneDrive*' -ea SilentlyContinue | Unregister-ScheduledTask -Confirm:$False
}
catch {
    throw "Failed to Unregister Several OneDrive Related Scheduled Tasks! $($_.Exception)"
}