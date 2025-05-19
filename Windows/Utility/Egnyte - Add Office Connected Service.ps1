
$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value

$CurrentServiceId = 'TP_EGNYTE_PLUS';

function Get-EgnyteConnectedServiceExists {
    param (
        $OfficeVersion
    )
    $exists = 0;
    $localServices = Get-ChildItem -Path "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Office\$OfficeVersion\Common\ServicesManagerCache\Local"
    foreach ($value in $localServices) {
        $service = Get-ItemProperty "Registry::HKEY_USERS\$strUserSID\$value"
        if ($service.ServiceId -eq $CurrentServiceId) {
            $exists = 1;
            break
        }
    }
    $exists;
}

function Get-OfficeVersion {
    $officeVersionX32 = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Office\ClickToRun\Configuration' -ErrorAction SilentlyContinue -WarningAction SilentlyContinue) | Select-Object -ExpandProperty VersionToReport
    $officeVersionX64 = (Get-ItemProperty -Path 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Office\ClickToRun\Configuration' -ErrorAction SilentlyContinue -WarningAction SilentlyContinue) | Select-Object -ExpandProperty VersionToReport
    if ($null -ne $officeVersionX32 -and $null -ne $officeVersionX64) {
        $officeVersion = $officeVersionX64
    } 
    elseif($null -eq $officeVersionX32 -or $null -eq $officeVersionX64) {
        $officeVersion = $officeVersionX32 + $officeVersionX64
    }
    $officeVersionMain = $officeVersion.Split(".")[0] + '.0'
    $officeVersionMain
}

$officeVersion = Get-OfficeVersion
Write-Host "Current Office Version: $officeVersion"
$egnyteExists = Get-EgnyteConnectedServiceExists -OfficeVersion $officeVersion

if($egnyteExists -eq 0) {
    Write-Host "Egnyte not Found, Running Provisioning Script."
    Start-Process "ms-office-storage-host:asp|d|$CurrentServiceId|o|1|a|script"
} 
else {
    Write-Host "Egnyte Found for User '$($strActiveUser)' Exiting..."
}