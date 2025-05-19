
if (-not (Test-Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST")) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Force #PRIVATE
}

function Show-Notification {
    [CmdletBinding()]
    Param (
        [string]
        $ApplicationId,
        [string]
        $ToastTitle,
        [string]
        [Parameter(ValueFromPipeline)]
        $ToastText,
        [switch]
        $UseHintCrop
    )

    # Import all the needed libraries
    [Windows.UI.Notifications.ToastNotificationManager, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
    [Windows.UI.Notifications.ToastNotification, Windows.UI.Notifications, ContentType = WindowsRuntime] > $null
    [Windows.System.User, Windows.System, ContentType = WindowsRuntime] > $null
    [Windows.System.UserType, Windows.System, ContentType = WindowsRuntime] > $null
    [Windows.System.UserAuthenticationStatus, Windows.System, ContentType = WindowsRuntime] > $null
    [Windows.Storage.ApplicationData, Windows.Storage, ContentType = WindowsRuntime] > $null

    # Make sure that we can use the toast manager, also checks if the service is running and responding
    try {
        $ToastNotifier = [Windows.UI.Notifications.ToastNotificationManager]::CreateToastNotifier("$ApplicationId")
    }
    catch {
        throw "[Error] Failed to create notification. $($_.Exception)"
    }

    # Create a new toast notification
    $RawXml = [xml] @"
<toast>
<visual>
<binding template='ToastGeneric'>
    <text id='1'>$ToastTitle</text>
    <text id='2'>$ToastText</text>
    <image placement='appLogoOverride' src='$ImagePath' $(if($UseHintCrop){ "hint-crop='circle'" })/>
</binding>
</visual>
</toast>
"@

    # Serialized Xml for later consumption
    $SerializedXml = New-Object Windows.Data.Xml.Dom.XmlDocument
    $SerializedXml.LoadXml($RawXml.OuterXml)

    # Setup how are toast will act, such as expiration time
    $Toast = $null
    $Toast = [Windows.UI.Notifications.ToastNotification]::new($SerializedXml)
    $Toast.Tag = "PowerShell"
    $Toast.Group = "PowerShell"
    $Toast.ExpirationTime = [DateTimeOffset]::Now.AddMinutes(1)

    # Show our message to the user
    $ToastNotifier.Show($Toast)
}

if($null -eq $env:regkey) { 
    throw "A regkey is required!"
}
else {
    $strRegKey = $env:regkey
}

$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName

# Get the SID (Security Identifier) of the active user
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value

if (-not (Test-Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST")) {
    New-Item -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Force
}

$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'
try {
    [string]$strRegVal = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST' -Name $strRegKey).$strRegKey
} catch {
    $strRegVal = $null
}
$ErrorActionPreference = $oldErrorActionPreference

if ($strRegVal -ne '1') {
    [string]$Title = $env:title
    [string]$Message = $env:message

    if($null -eq $Title) { 
        throw "A title is required!"
    }
    if($null -eq $Message) { 
        throw "A message is required!"
    }

    if ([String]::IsNullOrWhiteSpace($Title)) {
        throw "[Error] A Title is required."
    }
    if ([String]::IsNullOrWhiteSpace($Message)) {
        throw "[Error] A Message is required."
        exit 1
    }

    if ($Title.Length -gt 64) {
        throw "[Error] The Title is longer than 64 characters. The title will be truncated by the Windows API to 64 characters."
    }
    if ($Message.Length -gt 200) {
        throw "[Error] The Message is longer than 200 characters. The message might get truncated by the Windows API."
    }

    if ($([System.Security.Principal.WindowsIdentity]::GetCurrent()).Name -like "NT AUTHORITY*" -or $([System.Security.Principal.WindowsIdentity]::GetCurrent()).IsSystem) {
        throw "[Error] Please run this script as 'Current Logged on User'."
    }

    $Base64 = ''

    [string]$ImagePath = "$($env:USERPROFILE)\AppData\Local\Temp\TST.png"
    $ApplicationId = "TEST"

    if (-not (Test-Path -Path (Split-Path -Path $ImagePath -Parent) -ErrorAction SilentlyContinue)) {
        try {
            New-Item "$(Split-Path -Path $ImagePath -Parent)" -ItemType Directory -ErrorAction Stop
            Write-Host "[Info] Created folder: $(Split-Path -Path $ImagePath -Parent)"
        }
        catch {
            throw "[Error] Failed to create folder: $(Split-Path -Path $ImagePath -Parent)"
        }
    }

    $strRegPath = "HKCU:\SOFTWARE\Classes\AppUserModelId\$($ApplicationId -replace '\s+','.')"

    if (-not $(Test-Path -Path $strRegPath)) {
        # Check if path does not exist and create the path
        New-Item -Path $strRegPath -Force | Out-Null
    }


    if ((Get-ItemProperty -Path $strRegPath -Name "DisplayName" -ErrorAction Ignore)) {
        try {
            Set-ItemProperty -Path $strRegPath -Name "DisplayName" -Value $ApplicationId -Force -Confirm:$false -ErrorAction Stop | Out-Null
        }
        catch {
            Write-Error "[Error] Unable to Set registry key for $Name please see below error!"
            Write-Error $_
            exit 1
        }
    }
    else {
        New-ItemProperty -Path $strRegPath -Name "DisplayName" -Value $ApplicationId -PropertyType String -Force -Confirm:$false -ErrorAction Stop | Out-Null
    }

    [IO.File]::WriteAllBytes($ImagePath, $([Convert]::FromBase64String($Base64)))

    if ((Get-ItemProperty -Path $strRegPath -Name "IconUri" -ErrorAction Ignore)) {
        try {
            Set-ItemProperty -Path $strRegPath -Name "IconUri" -Value $ImagePath -Force -Confirm:$false -ErrorAction Stop | Out-Null
        }
        catch {
            throw "[Error] Unable to Set Registry Key for $Name $($_.Exception)"
        }
    }
    else {
        try {
            New-ItemProperty -Path $strRegPath -Name "IconUri" -Value $ImagePath -PropertyType String -Force -Confirm:$false -ErrorAction Stop | Out-Null
        }
        catch {
            throw "[Error] Failed to Create Regkey $strRegPath $($_.Exception)"
        }
    }

    try {
        Write-Host "[Info] Attempting to send message to user..."
        $NotificationParams = @{
            ToastTitle    = $Title
            ToastText     = $Message
            ApplicationId = "$($ApplicationId -replace '\s+','.')"
            UseHintCrop   = $False
        }
        Show-Notification @NotificationParams -ErrorAction Stop
        Write-Host "[Info] Message sent to user."
    }
    catch {
        throw "[Error] Failed to send message to user. $($_.Exception)"
    }

    exit 0
}
if ($strRegVal -eq '1') {
    Write-Host "$strRegKey Message Already Presented!"
}