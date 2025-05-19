if(($env:downloadURL).Length -le 0){
    throw "Please Provide a Value for the Download URL Parameter"
}

#region Variable Declarations

$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
# Name of Software to be Installed.
$strSoftwareName = "Ninja Remote"
$strarrRegDisplayName = @("Ninja Remote")
# Download URL.
$strDownloadURL = $env:downloadURL
# Installer MSI temp folder location.
$strFolderPath = "$($env:TEMP)\TEST" #PRIVATE
# Installer MSI file name.
$strarrDownloadURL = $strDownloadURL -split '/'
$strInstallerFileName = $strarrDownloadURL[-1]
# Installer MSI file location.
$strDestinationPath = "$strFolderPath\$strInstallerFileName"

$uninstallKeys = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

#endregion

#region Check If Already Installed
foreach ($key in $uninstallKeys) {
    foreach($objRegKey in $(Get-ItemProperty $key)){
        foreach($strRegDisplayName in $strarrRegDisplayName){
            if($objRegKey.DisplayName -eq $strRegDisplayName){
                Write-Host "[Informational] $strSoftwareName already installed. Exiting."
                Exit 0
            }
        }
    }
}

# If not installed, check for required folder path and create if required.
if(!(Test-Path -Path $strFolderPath)){
    New-Item -ItemType Directory -Path $strFolderPath -Force -Confirm:$False
}

# Check if a previous attempt failed, leaving the installer in the temp directory and breaking the script. If so, remove existing installer and re-download.
if (Test-Path -Path $strFolderPath) {
    Remove-Item $strFolderPath -Force -ErrorAction SilentlyContinue -Recurse -Include *.*
    Write-Host "[Informational] Removed $strFolderPath..."
}
#endregion

#region Download Software
try {
    Write-Output "Beginning download of $strSoftwareName to $strDestinationPath"
    Invoke-WebRequest -Uri "$strDownloadURL" -OutFile "$strDestinationPath"
} catch {
    throw "[Error] Error Downloading - $($_.Exception)"
}
#endregion  
 
#region Begin Install
try {
    # Start the install
    Write-Output "[Informational] Initiating install of $strSoftwareName..."
    #Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$strDestinationPath`" /quiet /norestart" -Wait -NoNewWindow
    Start-Process "$strDestinationPath" -ArgumentList "-silentAndAcceptEULA" -Wait
} catch {
    throw "[Error] Error installing $strSoftwareName Exception: $($_.Exception)"
}
# Define maximum number of checks and interval
$maxChecks = 10
$checkInterval = 30  # in seconds
$currentCheck = 0

while ($currentCheck -lt $maxChecks) {
    Start-Sleep -Seconds $checkInterval
    $currentCheck++

    Write-Host "[Informational] Checking installation status... (Attempt $currentCheck of $maxChecks)"

    $installed = $false

    foreach ($key in $uninstallKeys) {
        foreach ($objRegKey in Get-ItemProperty $key -ErrorAction SilentlyContinue) {
            foreach ($strRegDisplayName in $strarrRegDisplayName) {
                if ($objRegKey.DisplayName -eq $strRegDisplayName) {
                    $installed = $true
                    break
                }
            }
            if ($installed) { break }
        }
        if ($installed) { break }
    }

    if ($installed) {
        Remove-Item $strFolderPath -Force -ErrorAction SilentlyContinue -Recurse -Include *.*
        Write-Host "[Informational] Removed $strFolderPath..."
        Write-Host "[Informational] $strSoftwareName successfully installed."
        Exit 0
    }
}
#endregion