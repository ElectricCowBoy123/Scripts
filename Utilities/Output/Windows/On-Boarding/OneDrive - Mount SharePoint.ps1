Add-Type -AssemblyName System.Web

function Set-RegistryKey {
    param(
        [String] $name,
        [String] $value,
        [String] $type
    )

    if($firstRun){
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
                    Write-Host "Failed to Terminate Process: $($proc.Name) (ID: $($proc.Id)). Continuing Anyway... Error: $_"
                }
            }
            $firstRun = $False
        }
        else {
            Write-Host "No OneDrive Processes Found, Proceeding..."
            $firstRun = $False
        }
        New-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'OD' -PropertyType 'String' -Value '1' -ErrorAction SilentlyContinue
    }
    
    if($null -ne $(Get-ItemProperty -Path "Registry::$($key)" -Name "$($name)" -ErrorAction SilentlyContinue)){
        Write-Host "Setting Registry Key $($key)\$($name)"
        Set-ItemProperty -Path "Registry::$($key)" -Name "$($name)" -Value "$value" -Type "$type" -Force -Confirm:$false -ErrorAction Stop | Out-Null
    }
    else {
        Write-Host "Creating Registry Key $($key)\$($name)"
        New-ItemProperty -Path "Registry::$($key)" -Name "$($name)" -Value "$value" -PropertyType "$type" -Force -ErrorAction Stop | Out-Null
    }
}

$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
$strUsername = $strActiveUser.Split('\')[1]

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

$firstRun = $False

if($null -eq $app){
    throw "[Error] OneDrive is Not Installed!"
}
else {
    if (-not (Test-Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST")) {
        New-Item -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Force
    }
    $oldErrorActionPreference = $ErrorActionPreference
    $ErrorActionPreference = 'SilentlyContinue'
    try {
        [string]$strODVal = (Get-ItemProperty -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'OD').OD
    } catch {
        $strODVal = $null
    }
    $ErrorActionPreference = $oldErrorActionPreference

    if($strODVal -ne '1'){
        $firstRun = $True
    }
    else {
        Write-Host "Re-applying Group Policy Settings..."
    }
}
<#
if($null -ne $env:sharePointLibraryID -and $env:libraryName.Length -gt 0){
    $sharePointLibraryIDObj = $($env:sharePointLibraryID).ToString()
    $sharePointLibraryIDObj = $sharePointLibraryIDObj -split '&' | ForEach-Object { $keyValue = $_ -split '='; [PSCustomObject]@{ Key = $keyValue[0]; Value = [System.Web.HttpUtility]::UrlDecode($keyValue[1]) } }
    foreach($obj in $sharePointLibraryIDObj){
        Write-Host $obj.Key
    }
    <#
    # Depreciated Ninja doesn't support the & symbol in string fields...
    if($($sharePointLibraryIDObj[0].Key) -ne "tenantId" -or $($sharePointLibraryIDObj[1].Key) -ne "siteId" -or $($sharePointLibraryIDObj[2].Key) -ne "webId" -or $($sharePointLibraryIDObj[3].Key) -ne "listId" -or $($sharePointLibraryIDObj[4].Key) -ne "webUrl"){
        throw "Invalid SharePoint Library ID Structure..."
    }
    
}
#>

$config = @{
    "HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\OneDrive\TenantAutoMount" = @{
        "$($env:libraryName)" = @{
            "Type" = "String"
            "Value" = "$([uri]::UnescapeDataString($("tenantId=$($env:tenantID)&siteId=$($env:siteId)&webId=$($env:webId)&listId=$($env:listId)&webUrl=$($env:webUrl)&version=1")))"
            #$("tenantId=$($sharePointLibraryIDObj[0].Value)&siteId=$($sharePointLibraryIDObj[1].Value)&webId=$($sharePointLibraryIDObj[2].Value)&listId=$($sharePointLibraryIDObj[3].Value)&webUrl=$($sharePointLibraryIDObj[4].Value)&version=1"))
        }
    }
}
if($firstRun){ 
    Write-Host "Applying Group Policy Settings..."
}
foreach($key in $config.Keys){
    if(-not (Test-Path -Path "Registry::$($key)")){
        New-Item -Path "Registry::$($key)" -Force
    }
    foreach($subkey in $config[$key].Keys){
        $name = $subkey
        $value = $config[$key][$subkey]["Value"]
        $type = $config[$key][$subkey]["Type"]

        try {
            if($env:tenantID.Length -gt 0 -and $env:siteId.Length -gt 0 -and $env:libraryName.Length -gt 0 -and $env:webId.Length -gt 0 -and $env:listId.Length -gt 0 -and $env:webUrl.Length -gt 0){
                Set-RegistryKey -Name $name -Value $value -Type $type
            }
            else{
                throw "Please Provide Values for the Following Properties: siteId, libraryName, webId, listId, webUrl"
            }
        }
        catch {
            throw "[Error] Unable to Set or Create Registry Keys for Registry Location: $($key)\$($name) $($_.Exception)"
        }
    }
}