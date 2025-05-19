# Define the MSI Product Code to search for
$productCode = "{FFD8CF3D-3063-4D97-B007-26258E71D02F}"

# Function to check if the product is installed
function Check-ProductInstalled {
    param (
        [string]$productCode
    )
    # Check via Win32_Product
    $installedProduct = Get-WmiObject -Class Win32_Product | Where-Object { $_.IdentifyingNumber -eq $productCode }
    if ($installedProduct) {
        Write-Host "Product found via Win32_Product:"
        Write-Host "Name: $($installedProduct.Name)"
        Write-Host "Version: $($installedProduct.Version)"
        return $true
    }

    # Check via Registry
    $registryPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall"
    $installedProduct = Get-ChildItem -Path $registryPath | ForEach-Object {
        $product = Get-ItemProperty -Path $_.PSPath
        if ($product.PSChildName -eq $productCode) {
            Write-Host "Product found in Registry:"
            Write-Host "Name: $($product.DisplayName)"
            Write-Host "Version: $($product.DisplayVersion)"
            return $true
        }
    }

    return $false
}

# Function to remove orphaned MSI entry
function Remove-OrphanedMSIEntry {
    param (
        [string]$productCode
    )
    # Use MSIEXEC to forcefully remove the product
    Write-Host "Attempting to remove orphaned MSI entry for Product Code: $productCode"
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/x $productCode /qn" -Wait
    Write-Host "Orphaned entry removal attempt completed."
}

# Main script logic
if (Check-ProductInstalled -productCode $productCode) {
    Write-Host "The product is already installed or has an orphaned entry."
} else {
    Write-Host "The product is not installed."
}

# Ask user if they want to remove the orphaned entry
$response = Read-Host "Do you want to attempt to remove the orphaned MSI entry? (Y/N)"
if ($response -eq "Y" -or $response -eq "y") {
    Remove-OrphanedMSIEntry -productCode $productCode
} else {
    Write-Host "No action taken."
}