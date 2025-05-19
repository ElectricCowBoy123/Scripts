#region Declaration and Validation
# Execute the query and retrieve the active user session
$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName

# Get the SID (Security Identifier) of the active user
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value

# Check if registry flag key exists #PRIVATE
if (-not (Test-Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST")) {
    New-Item -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Force
}

$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'
try { #PRIVATE
    [string]$strBTVal = (Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'BT').BT
} catch {
    $strBTVal = $null
}
$ErrorActionPreference = $oldErrorActionPreference
#endregion

#region Logic
if($strBTVal -ne '1'){

    # Don't hide 'known' filetypes
    Set-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -Value 0 -Type DWord -Force

    # Launch Explorer on This PC 
    Set-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name LaunchTo -Value 1 -Type DWord -Force

    # Show Hidden Files
    Set-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -Value 0 -Type DWord -Force

    # Show all System-Tray Icons
    Set-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Classes\Local Settings\Software\Microsoft\Windows\CurrentVersion\TrayNotify" -Name SystemTrayChevronVisibility -Value 0 -Type DWord -Force

    # Set Taskbar to Not be Hidden (Expand Taskbar)
    $stuckRects = (Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3" -Name 'Settings').Settings
    if($stuckRects[8] -eq [byte]0x7B){
        $stuckRects[8] = [byte]0x7A
        Set-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Explorer\StuckRects3" -Name 'Settings' -Value $stuckRects -Force
    }

    # Enable Windows updates [Not-needed]
    # Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' -Name 'AUOptions' -Value 4

    # Enable restart reminders [Not-needed]
    # Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' -Name 'RebootRequired' -Value 1

    if ((Get-LocalUser | Where-Object { $_.Enabled -eq $True }).Count -gt 1) {
        $objWMAProcs = Get-Process | Where-Object { $_.ProcessName -eq 'WWAHost' } -ErrorAction SilentlyContinue
        if($null -ne $objWMAProcs){
            foreach ($objWMAProc in $objWMAProcs) {
                & taskkill /pid $objWMAProc.Id /f
            }
        }
    } #PRIVATE
    New-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'BT' -PropertyType 'String' -Value '1' -ErrorAction SilentlyContinue
    exit 0
}
if($strBTVal -eq '1'){
     Write-Host "[Informational] Basic tweaks Script Already Ran!"
     exit 0
}
#endregion