if($env:performReboot -ne '1' -and $env:performReboot -ne '0'){
    throw "Please supply a valid value for Perform Reboot"
}
if($env:performReboot -eq '1'){
    $performReboot = $True
}
if($env:performReboot -eq '0'){
    $performReboot = $False
}

if(-not $env:driveLetter){
    throw "Please supply a value for Drive Letter!"
}
elseif ($env:driveLetter -like '*/*' -or $env:driveLetter -like '*\*') {
    throw "Please supply a drive letter without any special characters!"
}
else {
    $env:driveLetter = $($env:driveLetter).ToUpper()
    $env:driveLetter = "$($env:driveLetter):"
    $driveLetter = $env:driveLetter
}

$bitLockerStatus = Get-BitLockerVolume -MountPoint $driveLetter

if ($bitLockerStatus.ProtectionStatus -eq 'On') {
    
    # Suspend BitLocker protection
    Suspend-BitLocker -MountPoint $driveLetter -RebootCount 0
    Write-Host "BitLocker protection has been suspended on drive $driveLetter."
} else {
    Write-Host "BitLocker is not enabled on drive $driveLetter."
}

if($performReboot){
    # Perform reboot
    Write-Host "Performing reboot..."
    Restart-Computer -Force
}
