if($($env:tenantID).Length -lt 36){
    throw "Please Supply a Valid Value for Tenant ID!"
}

$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
$strUsername = $strActiveUser.Split('\')[1]
$strDomain = $strActiveUser.Split('\')[0]

if($strDomain -eq $([Environment]::MachineName)){
    throw "[Error] Current User is Not a Domain User!"
}
else {
    if($strUsername -like '*TEST'){
        throw "[Error] This Cannot be Ran on a TEST Specific Account"
    }
    else {
        Write-Host "Applying Policy to User..."
    }
}

$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

foreach ($path in $uninstallPaths) {
    $app = Get-ItemProperty $path | Where-Object { $_.DisplayName -like "*OneDrive*" }
    if ($app) {
        break
    }
}

if($null -eq $app){
    throw "[Error] OneDrive is Not Installed!"
}
else {
    Write-Host "OneDrive is Installed, Resetting..."
    & "$($env:SYSTEMDRIVE)\Users\$($strUsername)\AppData\Local\Microsoft\OneDrive\onedrive.exe" /reset
    Write-Host "Killing OneDrive Processes..."
    $procs = Get-Process | Where-Object {$_.Name -like "*OneDrive*"}
    if($procs){
        foreach ($proc in $procs) {
            try {
                $proc.Kill()
                Write-Host "Terminated Process: $($proc.Name) (ID: $($proc.Id))"
            } 
            catch {
                throw "Failed to Terminate Process: $($proc.Name) (ID: $($proc.Id)). Error: $_"
            }
        }
    }
    else {
        Write-Host "No OneDrive Processes Found, Proceeding..."
    }
}

if((Test-Path -Path "Registry::HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\")){
    if(-not (Test-Path -Path "Registry::HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\OneDrive")){
        try {
            New-Item -Path "Registry::HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\OneDrive" -Force
        }
        catch {
            throw "[Error] Failed to Create RegPath: Registry::HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\OneDrive $($_.Exception)"
        }
    }

    if(Test-Path -Path "Registry::HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\OneDrive"){
        Write-Host "OneDrive is Installed, Enforcing Policy..."
        try {
            Write-Host "Enabling Policy: Coauthoring and In-app Sharing for Office Files Using OneDrive..."
            if($null -ne $(Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\OneDrive" -Name "EnableAllOcsiClients" -ErrorAction SilentlyContinue)){
                Set-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\OneDrive" -Name "EnableAllOcsiClients" -Value 1 -Type DWord -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            else {
                New-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\OneDrive" -Name "EnableAllOcsiClients" -Value 1 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
            }
        }
        catch {
            throw "[Error] Unable to Set or Create Registry Keys for Registry Location: HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\OneDrive\EnableAllOcsiClients $($_.Exception)"
        }

        try {
            Write-Host "Enabling Policy: Prevent the Tutorial from Showing at the End of the OneDrive Setup..."
            if($null -ne $(Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\OneDrive" -Name "DisableTutorial" -ErrorAction SilentlyContinue)){
                Set-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\OneDrive" -Name "DisableTutorial" -Value 1 -Type DWord -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            else {
                New-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\OneDrive" -Name "DisableTutorial" -Value 1 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
            }
        }
        catch {
            throw "[Error] Unable to Set Registry Key: HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\OneDrive\DisableTutorial $($_.Exception)"
        }

        if($env:siteId.Length -gt 0 -and $env:libraryName.Length -gt 0 -and $env:webId.Length -gt 0 -and $env:listId.Length -gt 0 -and $env:webUrl.Length -gt 0){
            if(-not (Test-Path -Path "Registry::HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\OneDrive\TenantAutoMount")){
                try {
                    New-Item -Path "Registry::HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\OneDrive\TenantAutoMount" -Force
                }
                catch {
                    throw "[Error] Failed to Create Registry Path: Registry::HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\OneDrive\TenantAutoMount $($_.Exception)"
                }
            }

            try {
                Write-Host "Enabling Policy: Mount SharePoint Folders..."
                if($null -ne $(Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\OneDrive\TenantAutoMount" -Name "$($env:libraryName)" -ErrorAction SilentlyContinue)){
                    Set-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\OneDrive\TenantAutoMount" -Name "$($env:libraryName)" -Value "$([uri]::UnescapeDataString($("tenantId=$($env:tenantID)&siteId=$($env:siteId)&webId=$($env:webId)&listId=$($env:listId)&webUrl=$($env:webUrl)&version=1")))" -Type "String" -Force -Confirm:$false -ErrorAction Stop | Out-Null
                }
                else {
                    New-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\OneDrive\TenantAutoMount" -Name "$($env:libraryName)" -Value "$([uri]::UnescapeDataString($("tenantId=$($env:tenantID)&siteId=$($env:siteId)&webId=$($env:webId)&listId=$($env:listId)&webUrl=$($env:webUrl)&version=1")))" -PropertyType "String" -Force -ErrorAction Stop | Out-Null
                }
            }
            catch {
                throw "[Error] Unable to Set Registry Key: HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\OneDrive\TenantAutoMount\$($env:libraryName) $($_.Exception)"
            }         
        }
    }
}
if(Test-Path -Path "Registry::HKEY_USERS\$strUserSID\SOFTWARE\Microsoft\OneDrive\Accounts\Business1"){
    try {
        Write-Host "Ensuring SharePoint TimerAutoMount is Set to 1..."
        if($null -ne $(Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\SOFTWARE\Microsoft\OneDrive\Accounts\Business1" -Name "Timerautomount " -ErrorAction SilentlyContinue)){
            Set-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\SOFTWARE\Microsoft\OneDrive\Accounts\Business1" -Name "Timerautomount" -Value 1 -Type QWord -Force -Confirm:$false -ErrorAction Stop | Out-Null
        }
        else {
            New-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\SOFTWARE\Microsoft\OneDrive\Accounts\Business1" -Name "Timerautomount" -Value 1 -PropertyType QWord -Force -ErrorAction Stop | Out-Null
        }
    }
    catch {
        throw "[Error] Unable to Set or Create Registry Keys for Registry Location: HKEY_USERS\$strUserSID\SOFTWARE\Microsoft\OneDrive\Accounts\Business1\Timerautomount $($_.Exception)"
    }
}
if((Test-Path -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\")){
    try {
        New-Item -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Force
    }
    catch {
        throw "[Error] Failed to Create RegPath: Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive $($_.Exception)"
    }

    if(Test-Path -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive"){
        try {
            Write-Host "Enabling Policy: Silently Move Windows Known Folders to OneDrive..."
            if($null -ne $(Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMSilentOptIn" -ErrorAction SilentlyContinue)){
                Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMSilentOptIn" -Value "$env:tenantID" -Type "String" -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            else {
                New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMSilentOptIn" -Value "$env:tenantID" -PropertyType "String" -Force -ErrorAction Stop | Out-Null
            }
        }
        catch {
            throw "[Error] Unable to Set Registry Key: HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive\KFMSilentOptIn $($_.Exception)"
        }

        try {
            Write-Host "Enabling Policy: Silently Move the Desktop User Folder..."
            if($null -ne $(Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMSilentOptInDesktop" -ErrorAction SilentlyContinue)){
                Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMSilentOptInDesktop" -Value 1 -Type DWord -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            else {
                New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMSilentOptInDesktop" -Value 1 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
            }
        }
        catch {
            throw "[Error] Unable to Set Registry Keys for Registry Location: HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive\KFMSilentOptInDesktop $($_.Exception)"
        }
        
        try {
            Write-Host "Enabling Policy: Silently Move the Documents User Folder..."
            if($null -ne $(Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMSilentOptInDocuments" -ErrorAction SilentlyContinue)){
                Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMSilentOptInDocuments" -Value 1 -Type DWord -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            else {
                New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMSilentOptInDocuments" -Value 1 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
            }
        }
        catch {
            throw "[Error] Unable to Set Registry Keys for Registry Location: HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive\KFMSilentOptInDocuments $($_.Exception)"
        }

        try {
            Write-Host "Enabling Policy: Silently Move the Pictures User Folder..."
            if($null -ne $(Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMSilentOptInPictures" -ErrorAction SilentlyContinue)){
                Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMSilentOptInPictures" -Value 1 -Type DWord -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            else {
                New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMSilentOptInPictures" -Value 1 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
            }
        }
        catch {
            throw "[Error] Unable to Set Registry Keys for Registry Location: HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive\KFMSilentOptInPictures $($_.Exception)"
        }
        
        try {
            Write-Host "Enabling Policy: Show Notification for Successful Folder Redirections..."
            if($null -ne $(Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMSilentOptInWithNotification" -ErrorAction SilentlyContinue)){
                Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMSilentOptInWithNotification" -Value 1 -Type DWord -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            else {
                New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMSilentOptInWithNotification" -Value 1 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
            }
        }
        catch {
            throw "[Error] Unable to Set Registry Keys for Registry Location: HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive\KFMSilentOptInWithNotification $($_.Exception)"
        }
            
        try {
            Write-Host "Enabling Policy: Prevent Users from Redirecting their Windows known Folders to their PC..."
            if($null -ne $(Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMBlockOptOut" -ErrorAction SilentlyContinue)){
                Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMBlockOptOut" -Value 1 -Type DWord -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            else {
                New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Name "KFMBlockOptOut" -Value 1 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
            }
        }
        catch {
            throw "[Error] Unable to Set Registry Keys for Registry Location: HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive\KFMBlockOptOut $($_.Exception)"
        }
        
        try {
            Write-Host "Enabling Policy: Use OneDrive Files On-Demand (File Contents don't Download until a File is Opened)..."
            if($null -ne $(Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Name "FilesOnDemandEnabled" -ErrorAction SilentlyContinue)){
                Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Name "FilesOnDemandEnabled" -Value 1 -Type DWord -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            else {
                New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Name "FilesOnDemandEnabled" -Value 1 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
            }
        }
        catch {
            throw "[Error] Unable to Set Registry Keys for Registry Location: HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive\FilesOnDemandEnabled $($_.Exception)"
        }

        try {
            Write-Host "Enabling Policy: Silently Sign in Users to the OneDrive Sync App with their Windows Credentials...".
            if($null -ne $(Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Name "SilentAccountConfig" -ErrorAction SilentlyContinue)){
                Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Name "SilentAccountConfig" -Value 1 -Type DWord -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            else {
                New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive" -Name "SilentAccountConfig" -Value 1 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
            }
        }
        catch {
            throw "[Error] Unable to Set Registry Keys for Registry Location: HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\OneDrive\SilentAccountConfig $($_.Exception)"
        }
    }
}