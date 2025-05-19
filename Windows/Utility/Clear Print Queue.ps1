$obj = [System.Security.Principal.WindowsIdentity]::GetCurrent()

if($($obj.Name -notlike "NT AUTHORITY*")){
    throw "[Error] Access Denied. Please Run as SYSTEM."
}

Write-Host "Stopping Print Spooler Service"
$StopProcess = Start-Process -FilePath "$($env:SYSTEMDRIVE)\WINDOWS\system32\net.exe" -ArgumentList "stop", "spooler" -Wait -NoNewWindow -PassThru
if ($StopProcess.ExitCode -eq 0 -or $StopProcess.ExitCode -eq 2) {
    Write-Host "[Informational] Stopped Print Spooler Service"
    Start-Sleep -Seconds 10
    Write-Host "[Informational] Clearing all print queues"
    Remove-Item -Path "$env:SystemRoot\System32\spool\PRINTERS\*" -Force -ErrorAction SilentlyContinue
    Write-Host "[Informational] Cleared all Print Queues"
    Write-Host "[Informational] Starting Print Spooler Service"
    $StartProcess = Start-Process -FilePath "$($env:SYSTEMDRIVE)\WINDOWS\system32\net.exe" -ArgumentList "start", "spooler" -Wait -NoNewWindow -PassThru
    if ($StartProcess.ExitCode -eq 0) {
        Write-Host "[Informational] Started Print Spooler Service"
    }
    else {
        throw "[Error] Could Not Start Print Spooler Service. Net Start Spooler Returned Exit Code of $($StartProcess.ExitCode)"
    }
}
else {
    throw "[Error] Could not Stop Print Spooler Service. Net Stop Spooler Returned Exit Code of $($StopProcess.ExitCode)"
}
exit 0