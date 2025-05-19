$compareVersion = [version]"1.9.0"
$isSystem = $False
$obj = [System.Security.Principal.WindowsIdentity]::GetCurrent()

Write-Host $($obj.Name)
if($($obj.Name -like "NT AUTHORITY*") -eq $True){
    $isSystem = $True
}

if ($null -eq $env:softwareList -or ($env:softwareList -split ',').Length -eq 0) {
    throw "Please supply a comma-separated list of software to be installed! $($_.Exception)"
}

if($True -ne $isSystem -and $False -ne $isSystem){
    throw "Please Provide a Value for isSystem!"
}

$straSoftwareList = $env:softwareList -split ','

$wingetPath = $null
foreach($path in $(Get-ChildItem -Path "$($env:SYSTEMDRIVE)\Program Files\WindowsApps\" -Directory | Where-Object { $_.Name -like "*Microsoft.DesktopAppInstaller*" })){
    if($path.Name -notlike  "*neutral*"){
        $wingetPath = "$($path.FullName)\winget.exe"
        Write-Host "Winget Path: '$wingetPath'"
    }
}

if($null -eq $wingetPath -and $isSystem -eq $True){
    throw "[Error] Cannot Find Winget Path!"
}

if (-not (Test-Path -Path $wingetPath)) {
    throw "[Error] Cannot Find '$wingetPath'"
}

function Install-Software {
    param (
        [Parameter(Mandatory=$True)] 
        [array]$softwareList
    )
    Write-Host "Installing Software..."
    foreach($item in $softwareList){
            try {
                if($isSystem -eq $True){
                    Write-Host "Running as SYSTEM"
                    Start-Process "$wingetPath" -ArgumentList "install", "$item", "--disable-interactivity", "--accept-source-agreements", "--accept-package-agreements", "--scope", "machine" -Verb RunAs

                }
                else {
                    Write-Host "Running as USER"
                    Start-Process "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"winget install $item --disable-interactivity --accept-source-agreements --accept-package-agreements`"" -Verb RunAs -WindowStyle Hidden
                }
            }
            catch {
                throw "Failed to Install '$item' via Winget! $($_.Exception)"
            }
            Write-Host "Installed '$item'"
    }
}

$OSVersion = Get-WmiObject Win32_OperatingSystem | Select-Object BuildNumber

if($osVersion.BuildNumber -ge 22631){
    if($(Get-Command winget -ErrorAction SilentlyContinue).Length -gt 0 -or $(Test-Path -Path "$wingetPath")){
        $wingetVersion = winget --version
        $currentVersion = [version]$wingetVersion
        if ($currentVersion -lt $compareVersion) {
            throw "[Error] Please Update Winget Minimum Version is $($compareVersion)"
        }
        Install-Software -softwareList $straSoftwareList
    }
    else {
        throw "Winget is not Installed!"
    }
}
else {
    throw "Windows Version Less than 23H2! $($_.Exception)"
}