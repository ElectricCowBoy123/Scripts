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
    if($path.Name -notlike "*neutral*"){
        $wingetPath = Join-Path -Path $path.FullName -ChildPath "winget.exe"
        if(Test-Path -Path $wingetPath){
            Write-Host "Found winget.exe at: '$wingetPath'"
            break
        }
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
                    $pinfo = New-Object System.Diagnostics.ProcessStartInfo
                    $pinfo.FileName = "$wingetPath"
                    $pinfo.RedirectStandardError = $True
                    $pinfo.RedirectStandardOutput = $True
                    $pinfo.UseShellExecute = $False
                    $pinfo.Arguments = "`"install`" `"$item`" `"--disable-interactivity`" `"--accept-source-agreements`" `"--accept-package-agreements`" `"--scope`" `"machine`""
                    $p = New-Object System.Diagnostics.Process
                    $p.StartInfo = $pinfo
                    $p.Start() | Out-Null
                    $p.WaitForExit()
                    $stdout = $p.StandardOutput.ReadToEnd()
                    $stderr = $p.StandardError.ReadToEnd()
                    Write-Host "Output: `n $stdout"
                    if($stderr.length -gt 0) { 
                        Write-Host "Error: `n $stderr"
                    }

                    
                }
                else {
                    Write-Host "Running as USER"
                    Start-Process "powershell.exe" -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command `"winget install $item --disable-interactivity --accept-source-agreements --accept-package-agreements`"" -Verb RunAs -WindowStyle Hidden
                }
            }
            catch {
                throw "Failed to Install '$item' via Winget! $($_.Exception)"
            }
    }
}

$OSVersion = Get-WmiObject Win32_OperatingSystem | Select-Object BuildNumber

if($osVersion.BuildNumber -ge 22631){
    if($(Test-Path -Path "$wingetPath")){
        $wingetVersion = & "$wingetPath" --version
        $currentVersion = [version]$($wingetVersion.Split()[0].Replace("v", ""))
        Write-Host "Winget Version is $($currentVersion)"
        if ($currentVersion -lt $compareVersion) {
            throw "[Error] Please Update Winget Minimum Version is $($compareVersion)"
        }
        Install-Software -softwareList $straSoftwareList
    }
    elseif ($null -ne $(Get-Command "winget")) {
        $wingetVersion = & "winget" --version
        $currentVersion = [version]$($wingetVersion.Split()[0].Replace("v", ""))
        Write-Host "Winget Version is $($currentVersion)"
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