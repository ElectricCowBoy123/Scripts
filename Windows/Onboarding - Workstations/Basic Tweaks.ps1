function Ensure-NuGetProvider {
    # Check if the NuGet provider is installed
    $nugetProvider = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue

    if (-not $nugetProvider) {
        Write-Host "NuGet provider is not installed. Installing now..."
        Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
    } else {
        Write-Host "NuGet provider is already installed."
    }
}

function Ensure-PSWindowsUpdateModule {
    # Check if the PSWindowsUpdate module is installed
    if (-not (Get-Module -ListAvailable -Name PSWindowsUpdate)) {
        Write-Host "PSWindowsUpdate module is not installed. Installing now..."
        Install-Module -Name PSWindowsUpdate -Force -Scope CurrentUser
    } else {
        Write-Host "PSWindowsUpdate module is already installed."
    }
}

function Install-WindowsUpdates {
    # Install Windows Updates
    Write-Host "Installing Windows Updates..."
    Install-WindowsUpdate -AcceptAll
}

#region Declaration and Validation
# Execute the query and retrieve the active user session
$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName

# Get the SID (Security Identifier) of the active user
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value

# Check if registry flag key exists
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
$ErrorActionPreference = $oldErrorActionPreference
#endregion

#region Logic
if($strBTVal -ne '1'){

    # Don't hide 'known' filetypes
    Set-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name HideFileExt -Value 0 -Type DWord -Force

    # Launch Explorer on This PC 
    Set-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name LaunchTo -Value 1 -Type DWord -Force

    # Execute the functions
    Ensure-NuGetProvider
    Ensure-PSWindowsUpdateModule
    Install-WindowsUpdates
        
    # Enable restart reminders [Not-needed]
    # Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update' -Name 'RebootRequired' -Value 1

    if ((Get-LocalUser | Where-Object { $_.Enabled -eq $True }).Count -gt 1) {
        $objWMAProcs = Get-Process | Where-Object { $_.ProcessName -eq 'WWAHost' } -ErrorAction SilentlyContinue
        if($null -ne $objWMAProcs){
            foreach ($objWMAProc in $objWMAProcs) {
                & taskkill /pid $objWMAProc.Id /f
            }
        }
    }
    New-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'BT' -PropertyType 'String' -Value '1' -ErrorAction SilentlyContinue
    exit 0
}
if($strBTVal -eq '1'){
     Write-Host "[Informational] Basic tweaks Script Already Ran!"
     exit 0
}
#endregion