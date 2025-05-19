if ((Test-Path -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer")) {
    try {
        Write-Host "Enabling Policy: Turn-Off Autoplay for CD-ROM and Removable Media Drives...."
        Set-ItemProperty -Path "Registry::HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer" -Name "NoDriveTypeAutoRun" -Value 181 -Type DWord -Force -Confirm:$false -ErrorAction Stop | Out-Null
    }
    catch {
        throw "[Error] Unable to Set Registry Key: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer\NoDriveTypeAutoRun! $($_.Exception)"
    }
}
else {
    throw "[Error] Unable to Find Registry Key: HKEY_LOCAL_MACHINE\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer! $($_.Exception)"
}