function Start-Install {
    param (
        [Parameter(Mandatory = $True)]
        [String]$DestinationPath
    )

    $arrPath = $DestinationPath -split '\\'
    $joinedPath = [string]::Join('\', $arrPath[0..($arrPath.Length - 2)])

    $strInstallerLogFile = "$joinedPath\EgnyteDesktopAppInstallLog.txt"

    Write-Output "[Informational] Initiating install of $strSoftwareName..."
    try {
        Start-Process msiexec "/i `"$DestinationPath`" /qn /norestart" -wait
    }
    catch {
        Write-Output "[Error] Failed to install $strSoftwareName."
        Write-Output "[Error] HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\$strRegDisplayName"
        Write-Output "[Error] HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\$strRegDisplayName"
        Write-Output "[Error] If not present the installation has failed. Check the log file below for more detials"
        Write-Output "[Error] $strInstallerLogFile"
        Exit 1
    }
}

function Get-InstallStatus {
    param (
        [Parameter(Mandatory = $True)]
        $UninstallKeys,
        $RegDisplayNames,
        [bool]$OutputStatus
    )

    $maxChecks = 10
    $checkInterval = 30  # in seconds
    $currentCheck = 0

    while ($currentCheck -lt $maxChecks) {
        Start-Sleep -Seconds $checkInterval
        $currentCheck++
        if($OutputStatus){
            Write-Host "[Informational] Checking installation status... (Attempt $currentCheck of $maxChecks)"
        }
        $installed = $false
        foreach ($key in $UninstallKeys) {
            foreach ($objRegKey in Get-ItemProperty $key -ErrorAction SilentlyContinue) {
                foreach ($strRegDisplayName in $RegDisplayNames) {
                    if ($objRegKey.DisplayName -eq $strRegDisplayName) {
                        $installed = $true
                        break
                    }
                }
                if ($installed) { break }
            }
            if ($installed) { break }
        }
        if ($installed) { break }
    }
    return $installed
}

$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value

$strarruninstallKeys = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)


if ($env:downloadEgnyte -ne '1' -and $env:downloadEgnyte -ne '0'){ Throw "Please Supply a value for downloadEgnyte" } 

if($env:downloadEgnyte -eq '0'){
    if($null -eq $env:localPath){ 
        Throw "Please Provide a Value for localPath"
    }
}

#region Variable Declarations
# Name of Software to be Installed.
$strSoftwareName = "Egnyte"
# Uninstaller Display Names.
$strarrRegDisplayName = @("Egnyte Desktop App")

# Installer MSI file location & Download URL.
if($env:downloadEgnyte -eq '1'){
    $strDownloadURL = "https://egnyte-cdn.egnyte.com/egnytedrive/win/en-us/3.17.2/EgnyteDesktopApp_3.17.2_145.msi"
    $strInstallerFileName = "EgnyteDesktopApp_3.17.2_145.msi"
    $strFolderPath = "$env:TEMP\DIR" #PRIVATE
    $strDestinationPath = "$strFolderPath\$strInstallerFileName"
}
else {
    $strDestinationPath = $env:localPath
}

try {
    $boolInstalled = Get-InstallStatus -UninstallKeys $strarruninstallKeys -RegDisplayNames $strarrRegDisplayName -OutputStatus $False
}
catch {
    throw "Failed to Get Current Installation Status $($_.Exception)"
}

if ($boolInstalled) {
    Write-Host "[Informational] $strSoftwareName already installed."
    Exit 0
}

# If not installed, check for required folder path and create if required.
if($env:downloadEgnyte -eq '1'){
    if(!(Test-Path -PathType container $strFolderPath)) {
        New-Item -ItemType Directory -Path $strFolderPath
    }
    # Check if a previous attempt failed, leaving the installer in the temp directory and breaking the script. If so, remove existing installer and re-download.
    if (Test-Path $strDestinationPath) {
        Remove-Item $strDestinationPath
        Write-Output "[Informational] Removed $strDestinationPath..."
     }
}
#endregion

#region Logic
if($env:downloadEgnyte -eq '1'){
    try {
        Write-Output "[Informational] Beginning download of $strSoftwareName to $strDestinationPath"
        Invoke-WebRequest -Uri $strDownloadURL -OutFile $strDestinationPath
    } catch {
        Write-Output "[Error] Error Downloading - $_.Exception.Response.StatusCode.value_"
        Write-Output $_
        Exit 1
    }
    Start-Install -DestinationPath $strDestinationPath
}
else {
    Start-Install -DestinationPath $strDestinationPath
}

try {
    $boolInstalled = Get-InstallStatus -UninstallKeys $strarruninstallKeys -RegDisplayNames $strarrRegDisplayName -OutputStatus $True
}
catch {
    throw "Failed to Get Current Installation Status $($_.Exception)"
}

if ($boolInstalled) {
    Write-Host "[Informational] $strSoftwareName successfully installed."
    if($env:downloadEgnyte -eq '1'){
        Remove-Item $strFolderPath -Force -ErrorAction SilentlyContinue -Recurse -Include *.*
        Write-Host "[Informational] Removed $strFolderPath..."
    }
    Exit 0
}

#endregion