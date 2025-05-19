if(-not [int]::TryParse($env:timeOutInterval, [ref]$null)){
    throw "Please provide a valid value for timeOutInterval"
}

if(-not $($env:enableLockOut -eq "1" -or "2")){
    throw "Please provide a valid value for enableLockOut"
}

if($null -eq $env:enableLockOut -and $null -eq $env:timeOutInterval){
    throw "Please provide a value for enableLockOut or timeOutInterval"
}

$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName

# Get the SID (Security Identifier) of the active user
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value

if (-not (Test-Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST")) { #PRIVATE
    New-Item -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Force
}

if ((Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Control Panel\Desktop" -Name "ScreenSaveActive" -ErrorAction Ignore)) {
    try {
        if($null -ne $env:enableLockOut){
            Set-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Control Panel\Desktop" -Name "ScreenSaveActive" -Value "$env:enableLockOut" -Type "String" -Force -Confirm:$false -ErrorAction Stop | Out-Null
        }
        if($null -ne $env:timeOutInterval){
            Set-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Control Panel\Desktop" -Name "ScreenSaveTimeOut" -Value "$env:timeOutInterval" -Type "String" -Force -Confirm:$false -ErrorAction Stop | Out-Null
        }
    }
    catch {
        throw "[Error] Unable to Set registry key for Registry::HKEY_USERS\$strUserSID\Control Panel\Desktop! $($_.Exception)"
    }
}
else {
    try {
        if($null -ne $env:enableLockOut){
            New-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Control Panel\Desktop" -Name "ScreenSaveActive" -Value "$env:enableLockOut" -PropertyType String -Force -Confirm:$false -ErrorAction Stop | Out-Null
        }
        if($null -ne $env:timeOutInterval){
            New-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Control Panel\Desktop" -Name "ScreenSaveTimeOut" -Value "$env:timeOutInterval" -PropertyType String -Force -Confirm:$false -ErrorAction Stop | Out-Null
        }
    }
    catch {
        throw "[Error] Unable to Create registry key for Registry::HKEY_USERS\$strUserSID\Control Panel\Desktop! $($_.Exception)"
    }
}