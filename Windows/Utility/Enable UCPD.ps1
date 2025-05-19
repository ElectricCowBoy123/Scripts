$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
#PRIVATE
if (-not (Test-Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST")) {
    New-Item -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Force
}

$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'
try { #PRIVATE
    [string]$strEUCPDVal = (Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'EUCPD').EUCPD
} catch {
    $strEUCPDVal = $null
}
$ErrorActionPreference = $oldErrorActionPreference

$OSVersion = Get-WmiObject Win32_OperatingSystem | Select-Object BuildNumber

if($osVersion.BuildNumber -ge 26100 -and $strEUCPDVal -ne '1'){
    try {
        & "sc.exe" config UCPD start=auto
        & "schtasks.exe" /change /enable /TN "\Microsoft\Windows\AppxDeploymentClient\UCPD velocity" #PRIVATE
        New-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'EUCPD' -PropertyType 'String' -Value '1' -ErrorAction SilentlyContinue
        Write-Host "Enabling UCPD Successful, Reboot Required to Apply"
    }
    catch {
        throw "[Error] Failed to Enable UCPD $($_.Exception)"
    }
}
else {
    Write-Host "Script Doesn't Need to be Ran"
}