#region Parameter Validation
[Switch]$boolRemove = $False

if(-not $boolRemove){
    $strDownloadUrl = "https://SOMETHING.net/ninja/drivers/BROTHERMFC-J5740DW285B.zip"
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

# Name of Driver to be installed as shown inside the inf file.
$strDriverPath = "$strFolderPath\$strDriverFileName"

# Printer Port name to be used in Windows.
$strPrinterPortName = "TCPPort:$strPrinterPort"

#"https://SOMETHING.net/ninja/drivers/$strDriverZipFileName"

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
    
    # Begin the Install
    if ($null -eq (Get-Printer -name $strPrinterName -ErrorAction SilentlyContinue)) {
        # Check if driver is not already installed
        if ($null -eq (Get-PrinterDriver -name $strDriverName -ErrorAction SilentlyContinue)) {
            # Add the driver to the Windows Driver Store
            pnputil.exe /a "$strDriverPath"
            # Install the driver
            Add-PrinterDriver -Name "$strDriverName"
        } else {
            Remove-Printer -Name "$strDriverName"
            Restart-Service -Name Spooler
            Remove-PrinterDriver -Name "$strDriverName"
            Add-PrinterDriver -Name "$strDriverName"
            Write-Warning "Printer driver already installed, re-added"
        }

        # Check if printerport doesn't exist
        if ($null -eq (Get-PrinterPort -name $strPrinterPortName -ErrorAction SilentlyContinue)) {
            # Add printerPort
            Add-PrinterPort -Name $strPrinterPortName -PrinterHostAddress $strPrinterPort
        } else {
            Restart-Service -Name Spooler
            Remove-PrinterPort -Name $strPrinterPortName -PrinterHostAddress $strPrinterPort
            Add-PrinterPort -Name $strPrinterPortName -PrinterHostAddress $strPrinterPort
            Write-Warning "Printer port with name $($strPrinterPortName) already exists, re-added"
        }

        try {
            # Add the printer
            Add-Printer -Name $strPrinterName -DriverName $strDriverName -PortName $strPrinterPortName -ErrorAction stop
        } catch {
            throw "$($_.Exception.Message)"
        }

        Write-Host "Printer $strPrinterName successfully installed"

        if($boolRestart){
            & shutdown /r /f /t 300
        }

    } else {
        Write-Warning "Printer $strPrinterName already installed"
    }
    Remove-Item -Path "$strFolderPath" -Force -Confirm:$False -Recurse -Confirm:$False
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
    
    # Check if a previous attempt failed, leaving the driver files in the temp directory. If so, remove existing installer and re-download.
    if (Test-Path $strFolderPath) {
        Remove-Item $strFolderPath -Force -Recurse -Confirm:$False
        Write-Output "Removed $strFolderPath..."
    }

    # Download ZIP file and extract to specified location.
    # Check for required folder path and create if required.
    if (!(test-path -PathType container $strFolderPath)){
        New-Item -ItemType Directory -Path $strFolderPath -Force -Confirm:$False
    }

    # Check for required working folder path and create if required.
    if(!(test-path -PathType container $strWorkingFolder)){
        New-Item -ItemType Directory -Path $strWorkingFolder -Force -Confirm:$False
    }

    try {
        Write-Output "Beginning download to $strWorkingFolder"
        Invoke-WebRequest -OutFile "$strOutfilePath" -Uri "$strDownloadUrl"
    } catch {
        throw "[Error] Error Downloading - $($_.Exception.Response.StatusCode.value_)"
    }

    # Exract ZIP to Drivers folder.
    Expand-Archive -Path $strOutfilePath -DestinationPath "$strFolderPath" -Force -Confirm:$False 
    # Remove temporary file.
    Remove-Item -Path $strOutfilePath -Force -Confirm:$False -Recurse -Confirm:$False
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
        Remove-Printer -Name "$strPrinterName" -Verbose
        Get-PrinterDriver -Name "$strDriverName" | Remove-PrinterDriver -Verbose
        Remove-PrinterPort -Name "$strPrinterPortName"
        Restart-Service -Name Spooler -Force
    }
    catch {
        throw "[Error] Failed to remove network printer $strPrinterName. Exception: $_"
    }
    
}
#endregion

#region Logic
if (-not (funcIsElevated)) {
    throw "[Error] Access Denied. Please run with Administrator privileges."
}

if ($boolRemove){
    funcRemovePrinter -strDriverName $strDriverName -strPrinterName $strPrinterName -strPrinterPortName $strPrinterPortName
} else {

    try {
        funcDownloadDriver -strDriverFileName $strDriverFileName -strDriverName $strDriverName -strPrinterName $strPrinterName -strPrinterPortName $strPrinterPortName -strDownloadUrl $strDownloadUrl -strFolderPath $strFolderPath -strWorkingFolder $strWorkingFolder -strOutfilePath $strOutfilePath
    } catch {
        throw "[Error] Failed to download network printer $strPrinterName. Exception: $_"
    }
    
    try {
        funcInstallDriver -strDriverFileName $strDriverFileName -strDriverName $strDriverName -strPrinterName $strPrinterName -strPrinterPortName $strPrinterPortName -strDriverPath $strDriverPath -strPrinterPort $strPrinterPort
    } catch {
        throw "[Error] Failed to add network printer $strPrinterName. Exception: $_"
    }
}
#endregion