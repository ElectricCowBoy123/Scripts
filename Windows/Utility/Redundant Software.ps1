$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
$registryLocations = @(
    "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall",
    "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Uninstall"
)
foreach ($registryPath in $registryLocations) {
    try {
        $registryItems = Get-ChildItem -Path $registryPath -ErrorAction Stop
        foreach ($item in $registryItems) {
            try {
                $product = Get-ItemProperty -Path $item.PSPath -ErrorAction Stop
                if ($null -ne $product.PSChildName -and $product.PSChildName -eq $productCode) {
                    Write-Host "Product found in Registry:"
                    Write-Host "Name: $($product.DisplayName)"
                    if (-not [string]::IsNullOrEmpty($product.InstallLocation)) {
                        Write-Host "InstallLocation: $($product.InstallLocation)"
                        if (-not (Test-Path -Path $product.InstallLocation)) {
                            Write-Host "Redundant Install: $($product.InstallLocation)"
                        }
                    } else {
                        Write-Host "No installation location found"
                    }
                }
            }
            catch {
                Write-Warning "Failed to process registry item '$($item.Name)': $_"
            }
        }
    }
    catch {
        Write-Warning "Failed to access registry path '$registryPath': $_"
    }
}