Add-Type -AssemblyName System.Web

function Set-RegistryKey {
    param(
        [String] $name,
        [String] $value,
        [String] $type
    )

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
    $app = Get-ItemProperty $path | Where-Object { $_.DisplayName -like "*Microsoft 365*" }
    if ($app) {
        break
    }
}


if($null -eq $app){
    throw "[Error] Outlook is Not Installed!"
}
else {
    Write-Host "Outlook is Installed Proceeding..."
    Write-Host "Killing Outlook Processes..."
    $procs = Get-Process | Where-Object {$_.Name -like "*Outlook*"}
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
    }
    else {
        Write-Host "No Outlook Processes Found, Proceeding..."
    }
}

$config = @{
    "HKEY_USERS\$strUserSID\Software\Policies\Microsoft\office\16.0\outlook\options\calendar" = @{
        "weeknum" = @{
            "Type" = "DWord"
            "Value" = "1"
        }
    }
    "HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\office\16.0\outlook\preferences" = @{
        "delegatesentitemsstyle" = @{
            "Type" = "DWord"
            "Value" = "1"
        }
    }
    "HKEY_USERS\$strUserSID\SOFTWARE\Policies\Microsoft\office\16.0\outlook\autodiscover" = @{
        "zeroconfigexchange" = @{
            "Type" = "DWord"
            "Value" = "1"
        }
    }
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
            Set-RegistryKey -Name $name -Value $value -Type $type
        }
        catch {
            throw "[Error] Unable to Set or Create Registry Keys for Registry Location: $($key)\$($name) $($_.Exception)"
        }
    }
}