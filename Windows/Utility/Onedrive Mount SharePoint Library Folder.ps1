if ($env:libraryId -notmatch "siteId=" -or $env:libraryId -notmatch "tenantId=" -or $env:libraryId -notmatch "webId=" -or $env:libraryId -notmatch "version=" -or $env:libraryId -notmatch "webUrl=" -or $env:libraryId -notmatch "listId=" -or -not $env:libraryId) {
    throw "Invalid or no Library ID Supplied!"
}

if (-not $env:libraryName) {
    throw "Invalid or no Library Name Supplied!"
}

# Sanitize the input string by inserting ampersands before the property names
$propertyNames = @("tenantId=", "siteId=", "webId=", "listId=", "webUrl=", "version=")
$sanitizedString = $env:libraryId

foreach ($property in $propertyNames) {
    $sanitizedString = $sanitizedString -replace "(?<!&)$property", "&$property"
}

# Remove any leading ampersand if it exists
$sanitizedString = $sanitizedString.TrimStart('&')

Write-Host "URL: $($sanitizedString)`n"

$env:libraryId = $sanitizedString

$decodedString = [uri]::UnescapeDataString($env:libraryId)

$params = $decodedString -split '&' | ForEach-Object {
    $key, $value = $_ -split '='
    [PSCustomObject]@{ Key = $key; Value = $value }
}

foreach($param in $params){
    Write-Host "Param: $($param)`n"
}

$tenantId = ($params | Where-Object { $_.Key -eq 'tenantId' }).Value
if (-not $tenantId) {
    throw "[Error] tenantId is null or empty! Please check provided URL!"
}

$siteId = ($params | Where-Object { $_.Key -eq 'siteId' }).Value
if (-not $siteId) {
    throw "[Error] siteId is null or empty! Please check provided URL!"
}

$webId = ($params | Where-Object { $_.Key -eq 'webId' }).Value
if (-not $webId) {
    throw "[Error] webId is null or empty! Please check provided URL!"
}

$listId = ($params | Where-Object { $_.Key -eq 'listId' }).Value
if (-not $listId) {
    throw "[Error] listId is null or empty! Please check provided URL!"
}

$webUrl = ($params | Where-Object { $_.Key -eq 'webUrl' }).Value
if (-not $webUrl) {
    throw "[Error] webUrl is null or empty! Please check provided URL!"
}

$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
$strUsername = $strActiveUser.Split('\')[1]
$strDomain = $strActiveUser.Split('\')[0]



if($strDomain -eq $([Environment]::MachineName)){
    throw "[Error] Current User is Not a Domain User!"
}
else {
    if($strUsername -like '*TEST'){ #PRIVATE
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
        if($siteId.Length -gt 0 -and $env:libraryName.Length -gt 0 -and $webId.Length -gt 0 -and $listId.Length -gt 0 -and $webUrl.Length -gt 0){
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
                    Set-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\OneDrive\TenantAutoMount" -Name "$($env:libraryName)" -Value "$([uri]::UnescapeDataString($("tenantId=$($tenantId)&siteId=$($siteId)&webId=$($webId)&listId=$($listId)&webUrl=$($webUrl)&version=1")))" -Type "String" -Force -Confirm:$false -ErrorAction Stop | Out-Null
                }
                else {
                    New-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\OneDrive\TenantAutoMount" -Name "$($env:libraryName)" -Value "$([uri]::UnescapeDataString($("tenantId=$($tenantId)&siteId=$($siteId)&webId=$($webId)&listId=$($listId)&webUrl=$($webUrl)&version=1")))" -PropertyType "String" -Force -ErrorAction Stop | Out-Null
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