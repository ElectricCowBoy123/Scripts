$obj = [System.Security.Principal.WindowsIdentity]::GetCurrent()

if($($obj.Name -notlike "NT AUTHORITY*")){
    throw "[Error] Access Denied. Please Run as SYSTEM."
}

if ($env:printerName -and $env:printerName -notlike "null") { $Name = $env:printerName } else { throw "[Error] Please specify a Printer Name." }
if ($env:server -and $env:server -notlike "null") { $Server = $env:server } else { throw "[Error] Please specify a Server." }

[Switch]$Remove = [System.Convert]::ToBoolean($env:removePrinter)
[Switch]$Restart = [System.Convert]::ToBoolean($env:forceRestart)

try {
    $StartTime = Get-Date
    $AddOrRemove = if($Remove){"/gd"}else{"/ga"}

    Add-Printer -Connection "\\$Server\$Name"

    $Printer = Get-Printer -ComputerName $Server -Name $Name
    $PrinterDriver = Get-PrinterDriver -Name $Printer.DriverName -ComputerName $Server

    # rundll32.exe printui.dll, PrintUIEntry /ga /n\\$Server\$Name
    $Process = Start-Process -FilePath "$($env:SYSTEMDRIVE)\WINDOWS\system32\rundll32.exe" -ArgumentList @(
            "printui.dll,", "PrintUIEntry", $AddOrRemove, "/n`"\\$Server\$Name`""
    ) -PassThru -NoNewWindow

    while (-not $Process.HasExited) {
        if ($StartTime.AddMinutes(10) -lt $(Get-Date)) {
            throw "[Error] rundll32.exe printui.dll took longer than 10 minutes to complete. $($_.Exception)"
        }
        Start-Sleep -Milliseconds 100
    }

    Add-PrinterDriver -Name $PrinterDriver.Name

    Restart-Service -Name Spooler

    if ($(Get-Service -Name Spooler).Status -like "Running") {
        Write-Host "Restarted print Spooler service."
        Write-Host "Adding printer complete."
    }
    else {
        throw "[Error] Failed to restart Spooler service. $($_.Exception)"
    }

    if($Restart){
        Write-Host "A restart was requested scheduling restart for 60 seconds from now."
        Start-Process shutdown.exe -ArgumentList "/r /t 60" -Wait -NoNewWindow
    }else{
        Write-Host "A restart may be required for this script to take immediate effect."
    }
}
catch {
    throw "[Error] Failed to add network printer. $($_.Exception)"
}