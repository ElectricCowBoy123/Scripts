# Remove specified start up entry for all users

if($null -eq $env:registryKey){
    throw "Please Provide a Value for Registry Key"
}

$RegistryKey = $env:registryKey

$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
$strUsername = $strActiveUser.Split('\')[1]

$uninstallPaths = @(
    "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Run\*"
)

foreach ($path in $uninstallPaths) {
    $app = Get-ItemProperty $path | Where-Object { $_.DisplayName -like "*$RegistryKey*" }
    if ($app) {
        Write-Host "Removing: '$($app.PSChildName)'..."
        Remove-Item "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Run\$($app.PSChildName)" -Force
    }
}