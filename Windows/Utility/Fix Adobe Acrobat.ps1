$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
if (-not (Test-Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST")) {
    New-Item -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Force
}#PRIVATE
$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'
try { #PRIVATE
    [string]$strAARVal = (Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'AAR').AAR
} catch {
    $strAARVal = $null
}
$ErrorActionPreference = $oldErrorActionPreference
if($strAARVal -ne '1'){
    $boolKeepRunning = $True
    while($boolKeepRunning){
        if(Get-Process -Name "AcroRd32" -ErrorAction SilentlyContinue){
            Stop-Process -Name "AcroRd32" -Force
        }
        if(Get-Process -Name "AcroRd64" -ErrorAction SilentlyContinue){
            Stop-Process -Name "AcroRd64" -Force
        }
        if(Get-Process -Name "Acrobat" -ErrorAction SilentlyContinue){
            Stop-Process -Name "Acrobat" -Force
        }
        if(Get-Process -Name "AdobeUpdater" -ErrorAction SilentlyContinue){
            Stop-Process -Name "AdobeUpdater" -Force
        }
        if(Get-Process -Name "Acrotray" -ErrorAction SilentlyContinue){
            Stop-Process -Name "Acrotray" -Force
        }
        if(Get-Process -Name "AdobeIPCBroker" -ErrorAction SilentlyContinue){
            Stop-Process -Name "AdobeIPCBroker" -Force
        }
        if(Get-Process -Name "AdobeGCClient" -ErrorAction SilentlyContinue){
            Stop-Process -Name "AdobeGCClient" -Force
        }
        if(Get-Process -Name "AdobeCollabSync" -ErrorAction SilentlyContinue){
            Stop-Process -Name "AdobeCollabSync" -Force
        }
        Start-Sleep -Seconds 10
        if(Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE IdentifyingNumber = '{AC76BA86-1033-FFFF-7760-BC15014EA700}'") {
            try{ 
                & msiexec /x {AC76BA86-1033-FFFF-7760-BC15014EA700} /q
            }
            catch {
                throw "Failed to uninstall Adobe Acrobat"
            }
            Write-Host "Uninstalled Adobe Acrobat"
            $boolUninstalled = $True
        }
        if((Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE IdentifyingNumber = '{AC76BA86-1033-FFFF-7760-BC15014EA700}'") -and $boolUninstalled) {
            try {
                if(-not (Test-Path "\\10.60.1.22\Sources\Applications")){
                    throw "File share 10.60.1.22 not accessible!"
                }
                & msiexec /i "\\10.60.1.22\Sources\Applications\Adobe\20220623\Setup\APRO22.0\TEST\AcroPro.msi" /q
            }
            catch {
                throw "Failed to install Adobe Acrobat"
            }
            Write-Host "Installed Adobe Acrobat"
            $boolInstalled = $True
        }
        if((Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE IdentifyingNumber = '{AC76BA86-1033-FFFF-7760-BC15014EA700}'") -and $boolInstalled) {
            Write-Host "Success!"
            $boolKeepRunning = $True
        }
        if(-not (Get-WmiObject -Query "SELECT * FROM Win32_Product WHERE IdentifyingNumber = '{AC76BA86-1033-FFFF-7760-BC15014EA700}'") -and $null -eq $boolInstalled -and $null -eq $boolUninstalled){
            Write-Host "Adobe Acrobat is not installed!"
            exit 0
        }
    }
}
if($strAARVal -eq '1'){
    Write-Host "Adobe reinstall script already ran!"
    exit 0
}