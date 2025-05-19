$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value

$uninstallPaths = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

foreach ($path in $uninstallPaths) {
    $app = Get-ItemProperty $path | Where-Object { $_.DisplayName -like "*Edge*" }
    if ($app) {
        break
    }
}

if($null -eq $app){
    throw "[Error] Edge is Not Installed!"
}

if ((Test-Path -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft")) {
    if(-not (Test-Path -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge")){
        try {
            New-Item -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge" -Force
        }
        catch {
            throw "[Error] Failed to Create RegPath: Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge $($_.Exception)"
        }
    }

    if(-not (Test-Path -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge\Recommended")){
        try {
            New-Item -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge\Recommended" -Force
        }
        catch {
            throw "[Error] Failed to Create RegPath: Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge\Recommended $($_.Exception)"
        }
    }

    if(Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge" -Name 'RestoreOnStartup' -ErrorAction SilentlyContinue){
        try {
            Remove-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge" -Name 'RestoreOnStartup' -Force
        }
        catch {
            throw "[Error] Failed to Remove RegPath: Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge\ Name=RestoreOnStartup $($_.Exception)"
        }
    }
    
    if(Test-Path -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge\Recommended"){
        try {
            Write-Host "Enabling Policy: New Tab Page Search Box Uses the Address Bar to Search on New Tabs...."
            if($null -ne $(Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge\Recommended" -Name "NewTabPageSearchBox" -ErrorAction SilentlyContinue)){
                Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge\Recommended" -Name "NewTabPageSearchBox" -Value "redirect" -Type "String" -Force -Confirm:$false -ErrorAction Stop | Out-Null
                #Remove-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge\Recommended" -Name "NewTabPageSearchBox"
                # Windows updates have broken this functionality
            }
            else {
                New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge\Recommended" -Name "NewTabPageSearchBox" -Value "redirect" -PropertyType "String" -Force -ErrorAction Stop | Out-Null
            }
        }
        catch {
            throw "[Error] Unable to Set Registry Key: Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge\Recommended $($_.Exception)"
        }
    }

    if(Test-Path -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge"){
        try {
            Write-Host "Enabling Policy: Set Search Provider to Google...."
            if($null -ne $(Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge" -Name "DefaultSearchProviderSearchURL" -ErrorAction SilentlyContinue)){
                Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge" -Name "DefaultSearchProviderSearchURL" -Value "https://www.google.com/search?q={searchTerms}" -Type "String" -Force -Confirm:$false -ErrorAction Stop | Out-Null
                #Remove-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge" -Name "DefaultSearchProviderSearchURL"
                # Windows updates have broken this functionality
            }
            else {
                New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge" -Name "DefaultSearchProviderSearchURL" -Value "https://www.google.com/search?q={searchTerms}" -PropertyType "String" -Force -ErrorAction Stop | Out-Null
            }
        }
        catch {
            throw "[Error] Unable to Set Registry Key: HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge\DefaultSearchProviderSearchURL $($_.Exception)"
        }

        try {
            Write-Host "Enabling Policy: Enable Address Bar Query Search...."
            if($null -ne $(Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge" -Name "DefaultSearchProviderEnabled" -ErrorAction SilentlyContinue)){
                Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge" -Name "DefaultSearchProviderEnabled" -Value 1 -Type DWord -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            else {
                New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge" -Name "DefaultSearchProviderEnabled" -Value 1 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
            }
        }
        catch {
            throw "[Error] Unable to Set Registry Key: HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge\DefaultSearchProviderEnabled $($_.Exception)"
        }

        try {
            Write-Host "Enabling Policy: Hide Default New Page Top Sites...."
            if($null -ne $(Get-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge" -Name "NewTabPageHideDefaultTopSites" -ErrorAction SilentlyContinue)){
                Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge" -Name "NewTabPageHideDefaultTopSites" -Value 1 -Type DWord -Force -Confirm:$false -ErrorAction Stop | Out-Null
            }
            else {
                New-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge" -Name "NewTabPageHideDefaultTopSites" -Value 1 -PropertyType DWord -Force -ErrorAction Stop | Out-Null
            }
        }
        catch {
            throw "[Error] Unable to Set Registry Key: HKEY_LOCAL_MACHINE\SOFTWARE\Policies\Microsoft\Edge\NewTabPageHideDefaultTopSites $($_.Exception)"
        }
    }
}