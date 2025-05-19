#region Parameter Validation
[Switch]$boolRemove = $False

if(-not $boolRemove){
    $strDownloadUrl = "https://SOMETHING.net/ninja/drivers/BROTHERMFC-J5740DW285B.zip" #PRIVATE
    $strDriverFileName = "BRPRI20A.INF"
    $strPrinterName = "Brother MFC-J2740DW Printer"
    $strDriverName = "Brother MFC-J5740DW Printer"
    $strPrinterPort = "172.16.1.1"
    [Switch]$boolRestart = $False
    [Switch]$boolOutputParameterValues = $True
}
#endregion

#region Variable Declarations
# Temporary folder to store downloads
$strWorkingFolder = "$($env:TEMP)\TEST\Downloads"

# Printer Driver temp folder location.
$strFolderPath = "$($env:TEMP)\TEST\Drivers\$strDriverName"
#PRIVATE
# Name of Driver to be installed as shown inside the inf file.
$strDriverPath = "$strFolderPath\$strDriverFileName"

# Printer Port name to be used in Windows.
$strPrinterPortName = "TCPPort:$strPrinterPort"

$zipFileName = "BROTHERMFC-J5740DW285B.zip"
# Temporary file name for downloads
$strOutfilePath = "$strWorkingFolder\$zipFileName"
#endregion

#region Output Parameter Values
# Confirm Script Parameters.
if($boolOutputParameterValues){
    Write-Host "[Informational] List of parameters used in this script:"
    Write-Host "[Informational] Working Folder Path = $strWorkingFolder"
    Write-Host "[Informational] Output Folder Path = $strOutfilePath"
    Write-Host "[Informational] Download URL = $strDownloadUrl"
    Write-Host "[Informational] Driver File Name = $strDriverFileName"
    Write-Host "[Informational] Driver Path = $strDriverPath"
    Write-Host "[Informational] Folder Path = $strFolderPath"
    Write-Host "[Informational] Driver Name = $strDriverName"
    Write-Host "[Informational] Printer Name = $strPrinterName"
    Write-Host "[Informational] Printer Port = $strPrinterPort"
    Write-Host "[Informational] Printer Port Name = $strPrinterPortName"
    Write-Host "[Informational] Driver folder Name = $strDriverName"
    Write-Host "[Informational] End..."
}
#endregion

#region Function Declarations
function funcIsElevated {
    $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $p = New-Object System.Security.Principal.WindowsPrincipal($id)
    $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
}

function funcInstallDriver {
    param (
        [Parameter(Mandatory=$True)]
        [String]$strDriverFileName,
        [Parameter(Mandatory=$True)]
        [String]$strDriverName,
        [Parameter(Mandatory=$True)]
        [String]$strPrinterName,
        [Parameter(Mandatory=$True)]
        [String]$strPrinterPortName,
        [Parameter(Mandatory=$True)]
        [String]$strDriverPath,
        [Parameter(Mandatory=$True)]
        [String]$strPrinterPort
    )

    if ((Get-Printer -Name "$strPrinterName" -ErrorAction SilentlyContinue)) {
        Write-Warning "Printer $strPrinterName already installed. Attempting to remove..."
        Remove-Printer -Name "$strPrinterName"
        Start-Sleep -Seconds 2  # Wait for a moment to ensure removal
    }

    if ((Get-PrinterPort -Name "$strPrinterPortName" -ErrorAction SilentlyContinue)) {
        Remove-PrinterPort -Name "$strPrinterPortName"
        Write-Host "Removed existing printer port '$strPrinterPortName'"
        Start-Sleep -Seconds 2  # Wait for a moment to ensure removal
    }

    if (!(Get-PrinterDriver -Name "$strDriverName" -ErrorAction SilentlyContinue)) {
        pnputil.exe /a "$strDriverPath"
        Add-PrinterDriver -Name "$strDriverName"
    } else {
        Write-Warning "Printer driver already installed, re-adding..."
        Remove-PrinterDriver -Name "$strDriverName"
        Start-Sleep -Seconds 2  # Wait for a moment to ensure removal
        pnputil.exe /a "$strDriverPath"
        Add-PrinterDriver -Name "$strDriverName"
    }

    Add-PrinterPort -Name "$strPrinterPortName" -PrinterHostAddress "$strPrinterPort"
    Write-Host "Added printer port '$strPrinterPortName'"

    try {
        Add-Printer -Name "$strPrinterName" -DriverName "$strDriverName" -PortName "$strPrinterPortName" -ErrorAction Stop
    } catch {
        throw "$($_.Exception)"
    }

    Write-Host "Printer $strPrinterName successfully installed"

    if($boolRestart){
        & shutdown /r /f /t 300
    }

    Remove-Item -Path "$strFolderPath" -Force -Recurse
}


function funcDownloadDriver {
    param (
        [Parameter(Mandatory=$True)]
        [String]$strDriverFileName,
        [Parameter(Mandatory=$True)]
        [String]$strDriverName,
        [Parameter(Mandatory=$True)]
        [String]$strPrinterName,
        [Parameter(Mandatory=$True)]
        [String]$strPrinterPortName,
        [Parameter(Mandatory=$True)]
        [String]$strDownloadUrl,
        [Parameter(Mandatory=$True)]
        [String]$strFolderPath,
        [Parameter(Mandatory=$True)]
        [String]$strWorkingFolder,
        [Parameter(Mandatory=$True)]
        [String]$strOutfilePath
    )

    Write-Output "Adding Printer $strPrinterName, Port $strPrinterPortName and Driver $strDriverName"
    
    if (Test-Path "$strFolderPath") {
        Remove-Item $strFolderPath -Force -Recurse
        Write-Output "Removed $strFolderPath..."
    }

    if (!(Test-Path -PathType Container "$strFolderPath")){
        New-Item -ItemType Directory -Path "$strFolderPath" -Force
    }

    if(!(Test-Path -PathType Container "$strWorkingFolder")){
        New-Item -ItemType Directory -Path $strWorkingFolder -Force
    }

    try {
        Write-Output "Beginning download to $strWorkingFolder"
        Invoke-WebRequest -OutFile "$strOutfilePath" -Uri "$strDownloadUrl" -ErrorAction Stop
    } catch {
        throw "[Error] Error Downloading - $($_.Exception)"
    }

    Expand-Archive -Path "$strOutfilePath" -DestinationPath "$strFolderPath" -Force
    Remove-Item -Path "$strOutfilePath" -Force
}

function funcRemovePrinter {
    param (
        [Parameter(Mandatory=$True)]
        [String]$strDriverName,
        [Parameter(Mandatory=$True)]
        [String]$strPrinterName,
        [Parameter(Mandatory=$True)]
        [String]$strPrinterPortName
    )
    Write-Output "Removing Printer $strPrinterName, Port $strPrinterPortName and Driver $strDriverName"
    try {
        Remove-Printer -Name "$strPrinterName" -Force
        Get-PrinterDriver -Name "$strDriverName" | Remove-PrinterDriver -Force
        Remove-PrinterPort -Name "$strPrinterPortName"
        Restart-Service -Name Spooler -Force
    } catch {
        throw "[Error] Failed to remove network printer $strPrinterName. Exception: $($_.Exception)"
    }
}
#endregion

#region Logic
if (-not (funcIsElevated)) {
    throw "[Error] Access Denied. Please run with Administrator privileges."
}

if ($boolRemove) {
    funcRemovePrinter -strDriverName "$strDriverName" -strPrinterName "$strPrinterName" -strPrinterPortName "$strPrinterPortName"
} else {
    funcDownloadDriver -strDriverFileName "$strDriverFileName" -strDriverName "$strDriverName" -strPrinterName "$strPrinterName" -strPrinterPortName "$strPrinterPortName" -strDownloadUrl "$strDownloadUrl" -strFolderPath "$strFolderPath" -strWorkingFolder "$strWorkingFolder" -strOutfilePath "$strOutfilePath"
    
    
   
    funcInstallDriver -strDriverFileName "$strDriverFileName" -strDriverName "$strDriverName" -strPrinterName "$strPrinterName" -strPrinterPortName "$strPrinterPortName" -strDriverPath "$strDriverPath" -strPrinterPort "$strPrinterPort"

}
#endregion