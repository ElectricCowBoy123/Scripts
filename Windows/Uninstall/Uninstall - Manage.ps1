# Define the application display name
$strAppDisplayName = "ConnectWise Manage Client 64-bit"

# Define the process name
$processName = "ConnectWiseManage"  # Use the actual process name without spaces

# Check if the process is running and terminate it if it is
$process = Get-Process -Name $processName -ErrorAction SilentlyContinue

if ($process) {
    try {
        Stop-Process -Name $processName -Force
        Write-Host "Terminated: $processName"
    } catch {
        Write-Host "[Error] Failed to terminate process: $processName. Error: $($_.Exception.Message)"
    }
} else {
    Write-Host "Process $processName is not running."
}

# Retrieve uninstall strings from the registry
$strUninstallString32 = (Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -eq $strAppDisplayName }).UninstallString
$strQuietUninstallString32 = (Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -eq $strAppDisplayName }).QuietUninstallString

$strUninstallString64 = (Get-ItemProperty -Path "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -eq $strAppDisplayName }).UninstallString
$strQuietUninstallString64 = (Get-ItemProperty -Path "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*" | Where-Object { $_.DisplayName -eq $strAppDisplayName }).QuietUninstallString

# Output found uninstall strings
if ($strQuietUninstallString64) { Write-Output "[Informational] Found x64 quiet uninstall string: $strQuietUninstallString64" }
if ($strQuietUninstallString32) { Write-Output "[Informational] Found x32 quiet uninstall string: $strQuietUninstallString32" }
if ($strUninstallString32) { Write-Output "[Informational] Found x32 uninstall string: $strUninstallString32" }
if ($strUninstallString64) { Write-Output "[Informational] Found x64 uninstall string: $strUninstallString64" }

# Extract the product code from the uninstall strings
$msicode = $null  # Initialize the variable to store the product code

if ($strQuietUninstallString64 -match "\{(.*?)\}") {
    $msicode = $matches[1]  # Store the extracted product code
}
if ($strQuietUninstallString32 -match "\{(.*?)\}") {
    $msicode = $matches[1]  # Store the extracted product code
}
if ($strUninstallString32 -match "\{(.*?)\}") {
    $msicode = $matches[1]  # Store the extracted product code
}
if ($strUninstallString64 -match "\{(.*?)\}") {
    $msicode = $matches[1]  # Store the extracted product code
}

# Uninstall the application using msiexec if a product code was found
if ($msicode) {
    try {
        Write-Host "msicode: $msicode"
        Start-Process -FilePath "MsiExec.exe" -ArgumentList "/X {$msicode} /quiet /norestart" -Wait -NoNewWindow
        Write-Host "Uninstalled $strAppDisplayName"
    } catch {
        throw "[Error] Failed to uninstall $strAppDisplayName. $($_.Exception.Message)"
    }
} else {
    Write-Host "[Error] No valid uninstall string found for $strAppDisplayName."
}
