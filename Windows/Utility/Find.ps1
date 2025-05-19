if ($null -eq $env:searchString) {
    throw "Please Provide a Value for searchString!"
}

$uninstallKeys = @(
    "HKLM:\HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Services\*"
)

$results = @()

foreach ($key in $uninstallKeys) {
    foreach ($objRegKey in Get-ItemProperty $key) {
        if ($objRegKey.DisplayName -like "*$($env:searchString)*") {
            $fullPath = $objRegKey.PSPath
            $results += $objRegKey | Select-Object DisplayName, PSPath
        }
    }
}

if ($results.Count -gt 0) {
    $results | Format-List
} else {
    Write-Host "Nothing Found!"
}
