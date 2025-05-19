#


[CmdletBinding()]
param (
    [Parameter()]
    [String]$driverZipFileName,
    [Parameter()]
    [String]$driverFileName,
    [Parameter()]
    [String]$driverName,
    [Parameter()]
    [String]$printerName,
    [Parameter()]
    [String]$printerPort,
    [Parameter()]
    [Switch]$Remove = [System.Convert]::ToBoolean($env:removePrinter),
    [Parameter()]
    [Switch]$Restart = [System.Convert]::ToBoolean($env:forceRestart)
)

begin {
    function Test-IsElevated {
        $id = [System.Security.Principal.WindowsIdentity]::GetCurrent()
        $p = New-Object System.Security.Principal.WindowsPrincipal($id)
        $p.IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)
    }

    if ($env:driverZipFileName -and $env:driverZipFileName -notlike "null") { $driverZipFileName = $env:driverZipFileName }
    if ($env:driverInfFileName -and $env:driverInfFileName -notlike "null") { $driverFileName = $env:driverInfFileName }
    if ($env:driverName -and $env:driverName -notlike "null") { $driverName = $env:driverName }
    if ($env:printerName -and $env:printerName -notlike "null") { $printerName = $env:printerName }
    if ($env:printerIpAddress -and $env:printerIpAddress -notlike "null") { $printerPort = $env:printerIpAddress }

    Write-Host ""

    # Temporary folder to store downloads
    $workingFolder = "$env:TEMP\DIR\Downloads" #PRIVATE
    # Name of ZIP file you have uploaded which contains the drivers for this printer.
    $driverZipFileName = "$env:driverZipFileName"
    # Main inf Driver file name.
    $driverFileName = "$env:driverInfFileName"
    # Print Driver Name as referenced in the inf file.
    $driverName = "$env:driverName"
    # Name of Print Queue to be added to Windows.
    $printerName = "$env:printerName"
    # IP address of Printer to be used in the Printer Port.
    $printerPort = "$env:printerIpAddress"
    # 
    $driverNameNoSpaces = $driverName.replace(' ','')
    # Printer Driver temp folder location.
    $folderPath = "$env:TEMP\DIR\Drivers\$driverNameNoSpaces"
    # Name of Driver to be installed as shown inside the inf file.
    $driverPath = "$folderPath\$driverFileName"
    # Printer Port name to be used in Windows.
    $printerPortName = "TCPPort:$printerPort"
    # Url to download drivers from.
    $downloadUrl = "https://SOMETHING.net/ninja/drivers/$driverZipFileName"
    # Temporary file name for downloads
    $outfilePath = "$workingFolder\$driverName.zip"

    if (-not $driverZipFileName) {
        Write-Host "[Error] Please specify a Driver Zip File Name."
        exit 1
    }
    if (-not $driverFileName) {
        Write-Host "[Error] Please specify a Driver .inf File Name."
        exit 1
    }
    if (-not $driverName) {
        Write-Host "[Error] Please specify a Driver Name."
        exit 1
    }
    if (-not $printerName) {
        Write-Host "[Error] Please specify a Printer Name."
        exit 1
    }
    if (-not $printerPort) {
        Write-Host "[Error] Please specify a Printer IP Address."
        exit 1
    }

    $ProcessTimeOut = 10

    # Confirm Script Variables.
    Write-Output "List of Variables used in this script:"
    Write-Output "Working Folder Path = $workingFolder"
    Write-Output "Output Folder Path = $outfilePath"
    Write-Output "Download Zip File Name = $driverZipFileName"
    Write-Output "Download URL = $downloadUrl"
    Write-Output "Driver File Name = $driverFileName"
    Write-Output "Driver Path = $driverPath"
    Write-Output "Folder Path = $folderPath"
    Write-Output "Driver Name = $driverName"
    Write-Output "Printer Name = $printerName"
    Write-Output "Printer Port = $printerPort"
    Write-Output "Printer Port Name = $printerPortName"
    Write-Output "Driver folder Name = $driverNameNoSpaces"
    Write-Output "Null = $null"
    Write-Output "End..."

}



process {
    if (-not (Test-IsElevated)) {
        Write-Error -Message "Access Denied. Please run with Administrator privileges."
        exit 1
    }
    if ($Remove){
      Write-Output "Removing Printer $printerName, Port $printerPortName and Driver $driverName"
        try {
            Remove-Printer -Name "$printerName" -Verbose
            Get-PrinterDriver -Name "$driverName" | Remove-PrinterDriver -Verbose
            Remove-PrinterPort -Name "$printerPortName"
        }
        catch {
            Write-Error $_
            Write-Host "[Error] Failed to remove network printer $printerName."
            exit 1
        }
    }
    else {
      Write-Output "Adding Printer $printerName, Port $printerPortName and Driver $driverName"
        # Check if a previous attempt failed, leaving the driver files in the temp directory. If so, remove existing installer and re-download.
        if (Test-Path $folderPath) {
            Remove-Item $folderPath
            Write-Output "Removed $folderPath..."
        }
        # Download ZIP file and extract to specifide location.
        # Check for required folder path and create if required.
        if (!(test-path -PathType container $folderPath)){
            New-Item -ItemType Directory -Path $folderPath
        }
        # Check for required working folder path and create if required.
        if(!(test-path -PathType container $workingFolder)){
            New-Item -ItemType Directory -Path $workingFolder
        }
        try {
            Write-Output "Beginning download of $driverZipFileName to $workingFolder"
            Invoke-WebRequest -OutFile "$outfilePath" $downloadUrl
        }
        catch {
            Write-Output "Error Downloading - $_.Exception.Response.StatusCode.value_"
            Write-Output $_
            Exit 1
        }
        # Exract ZIP to Drivers folder.
        $outfilePath | Expand-Archive -DestinationPath "$folderPath" -Force
        # Remove temporary file.
        $outfilePath | Remove-Item

        # Begin the Install
        if ($null -eq (Get-Printer -name $printerName -ErrorAction SilentlyContinue)) {
            # Check if driver is not already installed
            if ($null -eq (Get-PrinterDriver -name $driverName -ErrorAction SilentlyContinue)) {
            # Add the driver to the Windows Driver Store
            pnputil.exe /a "$driverPath"

            # Install the driver
            Add-PrinterDriver -Name $driverName
            } else {
            Write-Warning "Printer driver already installed"
            }

            # Check if printerport doesn't exist
            if ($null -eq (Get-PrinterPort -name $printerPortName)) {
            # Add printerPort
            Add-PrinterPort -Name $printerPortName -PrinterHostAddress $printerPort
            } else {
            Write-Warning "Printer port with name $($printerPortName) already exists"
            }

            try {
            # Add the printer
            Add-Printer -Name $printerName -DriverName $driverName -PortName $printerPortName -ErrorAction stop
            } catch {
            Write-Host $_.Exception.Message
            break
            }

            Write-Host "Printer $printerName successfully installed"
        } else {
        Write-Warning "Printer $printerName already installed"
        }

        catch {
        Write-Output "Error Downloading - $_.Exception.Response.StatusCode.value_"
        Write-Output $_
        Exit 1
        }

    catch {
        Write-Error $_
        Write-Host "[Error] Failed to add network printer $printerName."
        exit 1
    }
}

    exit 0
}

end {
     
}


<#

# Download ZIP file and extract to specifide location

# Check for required folder path and create if required.
if(!(test-path -PathType container $FolderPath))
{
      New-Item -ItemType Directory -Path $FolderPath
}
if(!(test-path -PathType container $workingFolder))
{
      New-Item -ItemType Directory -Path $workingFolder
}

-----------------------------------------------------------------------------------------

# Check if a previous attempt failed, leaving the installer in the temp directory and breaking the script. If so, remove existing installer and re-download.
if (Test-Path $folderPath) {
   Remove-Item $folderPath
   Write-Output "Removed $folderPath..."
}

-----------------------------------------------------------------------------------------

try
{
    Write-Output "Beginning download of $driverZipFileName to $workingFolder"
    Invoke-WebRequest -OutFile "$outfilePath" $downloadUrl
}
catch
{
    Write-Output "Error Downloading - $_.Exception.Response.StatusCode.value_"
    Write-Output $_
    Exit 1
}


# Exract ZIP to Drivers folder
$outfilePath | Expand-Archive -DestinationPath "$folderPath" -Force
# remove temporary file
$outfilePath | Remove-Item
##$tmp | Remove-Item

# Begin the Install
if ($null -eq (Get-Printer -name $printerName -ErrorAction SilentlyContinue)) {
    # Check if driver is not already installed
    if ($null -eq (Get-PrinterDriver -name $driverName -ErrorAction SilentlyContinue)) {
      # Add the driver to the Windows Driver Store
      pnputil.exe /a "$driverPath"

      # Install the driver
      Add-PrinterDriver -Name $driverName
    } else {
      Write-Warning "Printer driver already installed"
    }

    # Check if printerport doesn't exist
    if ($null -eq (Get-PrinterPort -name $printerPortName)) {
      # Add printerPort
      Add-PrinterPort -Name $printerPortName -PrinterHostAddress $printerPort
    } else {
      Write-Warning "Printer port with name $($printerPortName) already exists"
    }

    try {
      # Add the printer
      Add-Printer -Name $printerName -DriverName $driverName -PortName $printerPortName -ErrorAction stop
    } catch {
      Write-Host $_.Exception.Message -ForegroundColor Red
      break
    }

    Write-Host "Printer successfully installed"
} else {
 Write-Warning "Printer already installed"
}


#>