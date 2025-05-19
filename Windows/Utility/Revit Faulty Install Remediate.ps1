# Execute Installer
#& "\\10.60.1.22\Sources\Applications\Autodesk\Revit_2025\image\Installer.exe" -i deploy --offline_mode -q -o "\\10.60.1.22\Sources\Applications\Autodesk\Revit_2025\image\Collection.xml" --installer_version "2.13.0.557"

function Get-InstallStatus() {
    $process = Get-Process -Name "Installer" -ErrorAction SilentlyContinue
    if($process -ne $null){
        return $True
    }
    else {
        return $False
    }
}

function Get-DiskSpace(){
    $drive = Get-PSDrive -Name C
    $requiredSpace = 20GB
    if ($drive.Free -ge $requiredSpace) {
        return $True
    } else {
        return $False
    }
}

if (Get-InstallStatus) {
    Write-Host "Install in Progress"
    $installinprog = $True
    
}
else {
    Write-Host "Install is not in progress"
    $installinprog = $False
}

if(-not $(Test-Path -Path "C:\Windows\ccmcache")){
    Write-Host "No ccmcache folder"
}
else {
    # Get all items in the ccmcache directory
    $obj = Get-ChildItem -Path "C:\Windows\ccmcache" -ErrorAction SilentlyContinue

    if(-not $(Get-DiskSpace)){
        $drive = Get-PSDrive -Name C
        Write-Host "Seems there is not enough diskspace, investigate! SpaceFree: $($drive.Free)"
        exit(1)
    }
    foreach ($dir in $obj) {
        if ($dir.PSIsContainer) {
            $innerObj = Get-ChildItem -Path $dir.FullName -ErrorAction SilentlyContinue
            if ($innerObj.Name -contains "Installer.exe") {
                $size = (Get-ChildItem -Path $dir.FullName -Recurse -ErrorAction SilentlyContinue | Measure-Object -Property Length -Sum).Sum
                if ($size -gt 15600000000) {
                    if(-not $($installinprog)){
                        Write-Host "Executing Installer.exe"
                        & "$($dir.FullName)\Installer.exe" -i deploy --offline_mode -q -o "$($dir.FullName)\Collection.xml" --installer_version "2.13.0.557"
                    }
                } else {
                    Write-Host "Installer dir is less than 15600000000 bytes, still downloading?"
                }
            }
        }
    }
}



<#
if(Test-Path -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{7346B4A0-2500-0510-0000-705C0D862004}"){
    Write-Host "Installed Already"
    if(Get-InstallStatus){
        Write-Host "Install in Progress"
    }
}
else {
    if(Test-Path -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{686CE2A3-7C33-3AD5-806A-75A6E648117F}"){
        Remove-Item -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\{686CE2A3-7C33-3AD5-806A-75A6E648117F}" -Force
        Write-Host "ERROR: Removed Faulty Registry Key!"
        if(Test-Path -Path "C:\Program Files\Autodesk\Revit 2025"){
            Remove-Item -Path "C:\Program Files\Autodesk\Revit 2025" -Force -Recurse
            Write-Host "ERROR: Removed Faulty Files!"
        }
    }
}
#>