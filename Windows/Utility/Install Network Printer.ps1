#region Parameter Validation
if ($null -ne $env:removePrinter -and $env:removePrinter -ne ''){ [Switch]$boolRemove = [System.Convert]::ToBoolean($env:removePrinter) } else { throw "[Error] Please specify a value for the Remove Printer parameter." }

if(-not $boolRemove){
    if ($null -ne $env:downloadUrl -and $env:downloadUrl -ne '') { $strDownloadUrl = $env:downloadUrl } else { throw "[Error] Please specify a Download URL." }
    if ($null -ne $env:driverInfFileName -and $env:driverInfFileName -ne '') { $strDriverFileName = $env:driverInfFileName } else { throw "[Error] Please specify a Driver .inf File Name." }
    if ($null -ne $env:driverName -and $env:driverName -ne '') { $strDriverName = $env:driverName } else { throw "[Error] Please specify a Driver Name." }
    if ($null -ne $env:printerName -and $env:printerName -ne '') { $strPrinterName = $env:printerName } else { throw "[Error] Please specify a Printer Name." }
    if ($null -ne $env:printerIpAddress -and $env:printerIpAddress -ne '') { $strPrinterPort = $env:printerIpAddress } else { throw "[Error] Please specify a Printer IP Address." }
    if ($null -ne $env:forceRestart -and $env:forceRestart -ne ''){ [Switch]$boolRestart = [System.Convert]::ToBoolean($env:forceRestart) } else { throw "[Error] Please specify a value for the Force Restart parameter." }
    if ($null -ne $env:outputParameterValues -and $env:outputParameterValues -ne ''){ [Switch]$boolOutputParameterValues = [System.Convert]::ToBoolean($env:outputParameterValues) } else { throw "[Error] Please specify a value for the Output Parameter Values parameter." }
}
else {
    if ($null -ne $env:driverName -and $env:driverName -ne '') { $strDriverName = $env:driverName } else { throw "[Error] Please specify a Driver Name." }
    if ($null -ne $env:printerName -and $env:printerName -ne '') { $strPrinterName = $env:printerName } else { throw "[Error] Please specify a Printer Name." }
    if ($null -ne $env:printerIpAddress -and $env:printerIpAddress -ne '') { $strPrinterPort = $env:printerIpAddress } else { throw "[Error] Please specify a Printer IP Address." }
}
#endregion

#region Variable Declarations
# Temporary folder to store downloads
$strWorkingFolder = "$env:TEMP\DIR\Downloads" #PRIVATE

# Main inf Driver file name.
$strDriverFileName = "$env:driverInfFileName"

# Print Driver Name as referenced in the inf file.
$strDriverName = "$env:driverName"

# Name of Print Queue to be added to Windows.
$strPrinterName = "$env:printerName"

# IP address of Printer to be used in the Printer Port.
$strPrinterPort = "$env:printerIpAddress"

# Create the DriverName variable with no spaces.
$strDriverNameNoSpaces = $strDriverName.replace(' ','')

# Printer Driver temp folder location.
$strFolderPath = "$env:TEMP\DIR\Drivers\$strDriverNameNoSpaces"

# Name of Driver to be installed as shown inside the inf file.
$strDriverPath = "$strFolderPath\$strDriverFileName"

# Printer Port name to be used in Windows.
$strPrinterPortName = "TCPPort:$strPrinterPort"

# Url to download drivers from.
$strDownloadUrl = $env:downloadUrl
#"https://SOMETHING.net/ninja/drivers/$strDriverZipFileName"

# Temporary file name for downloads
$strOutfilePath = "$strWorkingFolder\$strDriverName.zip"
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
    Write-Host "[Informational] Driver folder Name = $strDriverNameNoSpaces"
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
            Add-PrinterDriver -Name $strDriverName
        } else {
            Write-Warning "Printer driver already installed"
        }

        # Check if printerport doesn't exist
        if ($null -eq (Get-PrinterPort -name $strPrinterPortName)) {
            # Add printerPort
            Add-PrinterPort -Name $strPrinterPortName -PrinterHostAddress $strPrinterPort
        } else {
            Write-Warning "Printer port with name $($strPrinterPortName) already exists"
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
        Remove-Item $strFolderPath
        Write-Output "Removed $strFolderPath..."
    }

    # Download ZIP file and extract to specified location.
    # Check for required folder path and create if required.
    if (!(test-path -PathType container $strFolderPath)){
        New-Item -ItemType Directory -Path $strFolderPath
    }

    # Check for required working folder path and create if required.
    if(!(test-path -PathType container $strWorkingFolder)){
        New-Item -ItemType Directory -Path $strWorkingFolder
    }

    try {
        Write-Output "Beginning download to $strWorkingFolder"
        Invoke-WebRequest -OutFile "$strOutfilePath" $strDownloadUrl
    } catch {
        throw "[Error] Error Downloading - $($_.Exception.Response.StatusCode.value_)"
    }

    # Exract ZIP to Drivers folder.
    $strOutfilePath | Expand-Archive -DestinationPath "$strFolderPath" -Force
    # Remove temporary file.
    $strOutfilePath | Remove-Item
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