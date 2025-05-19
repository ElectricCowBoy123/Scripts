<#
    Check if onboarding is needed or not, to be used in a Ninjarmm condition inside of a policy
#>
$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName

if(-not $strActiveUser.Length -gt 0){
    return 0 # Don't run the scripts
}

$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value

if (-not (Test-Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST")) { #PRIVATE
    New-Item -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Force
}

$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'
try {
    [string]$strBTVal = (Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'BT').BT
} catch {
    $strBTVal = $null
}

try {
    [string]$strCDBGVal = (Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'CDBG').CDBG
} catch {
    $strCDBGVal = $null
}

try {
    [string]$strCLVal = (Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'CL').CL
} catch {
    $strCLVal = $null
}

try {
    [string]$strCTVal = (Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'CT').CT
} catch {
    $strCTVal = $null
}

try {
    [string]$strCVLVal = (Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'CVL').CVL
} catch {
    $strCVLVal = $null
}

try {
    [string]$strDOVal = (Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'DO').DO
} catch {
    $strDOVal = $null
}

try {
    [string]$strDPSVal = (Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'DPS').DPS
} catch {
    $strDPSVal = $null
}

try {
    [string]$strENDVal = (Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'END').END
} catch {
    $strENDVal = $null
}

try {
    [string]$strRDIVal = (Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'RDI').RDI
} 
catch {
    $strRDIVal = $null
}

try {
    [string]$strTIVal = (Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'TI').TI
}
catch {
    $strTIVal = $null
}

try {
    [string]$strSDIVal = (Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'SDI').SDI
}
catch {
    $strSDIVal = $null
}

try {
    [string]$strSBEVal = (Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'SBE').SBE
}
catch {
    $strSBEVal = $null
}
$ErrorActionPreference = $oldErrorActionPreference

if($strBTVal -ne '1' -and $strCDBGVal -ne '1' -and $strCLVal -ne '1' -and $strCTVal -ne '1' -and $strCVLVal -ne '1' -and $strDOVal -ne '1' -and $strDPSVal -ne '1' -and $strENDVal -ne '1' -and $strRDIVal -ne '1' -and $strTIVal -ne '1' -and $strSDIVal -ne '1' -and $strSBEVal -ne '1'){
    return 1 # Run the scripts
}
else {
    return 0 # Don't run the scripts
}   