$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value

if (-not (Test-Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST")) {
    New-Item -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Force
} #PRIVATE

$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'
try {
    [string]$strDUCPDVal = (Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'DUCPD').DUCPD
} catch {
    $strDUCPDVal = $null
}
$ErrorActionPreference = $oldErrorActionPreference

$OSVersion = Get-WmiObject Win32_OperatingSystem | Select-Object BuildNumber

if($osVersion.BuildNumber -ge 26100 -and $strDUCPDVal -ne '1'){
    try {
        & "sc.exe" config UCPD start=disabled
        & "schtasks.exe" /change /disable /TN "\Microsoft\Windows\AppxDeploymentClient\UCPD velocity"
        New-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'DUCPD' -PropertyType 'String' -Value '1' -ErrorAction SilentlyContinue
        Write-Host "Disabling UCPD Successful, Rebooting Now..."
        & shutdown /r /t 00
    }
    catch {
        throw "[Error] Failed to disable UCPD $($_.Exception)"
    }
}
else {
    Write-Host "Script Doesn't Need to be Ran"
}