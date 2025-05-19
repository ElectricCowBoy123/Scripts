$clientConfig = @"
[General]
window_size=800, 600
DesktopLayout=FullscreenAllMonitors, 0, 800, 600, 0, 0
window_state=1, 0, 0, 0, 0, 0

[connection]
size=1
1\info=TEST, cloud.TEST.co.uk, admin, ad.TEST.co.uk, , 0, 1
"@

$clientConnectionConfig = @"
[General]
Version=1
security_mode=1
start_windowed=0
usb_auto_forward=true
max-pending-retry=0
language_ui=en_US
"@

$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
$teradiciPath = "$($env:SYSTEMDRIVE)\Users\$strActiveUser\AppData\Roaming\Teradici"

if(-not (Test-Path -Path "$teradiciPath\PCoIP Client Connection Info.ini")){
    throw "'$teradiciPath\PCoIP Client Connection Info.ini' Cannot be Found! $($_.Exception)"
}

if(-not (Test-Path -Path "$teradiciPath\Teradici PCoIP Client.ini")){
    throw "'$teradiciPath\Teradici PCoIP Client.ini' Cannot be Found! $($_.Exception)"
}

try {
    Set-Content -Path "$teradiciPath\PCoIP Client Connection Info.ini" -Value $clientConnectionConfig -Force
}
catch {
    throw "Failed to Write to File '$teradiciPath\PCoIP Client Connection Info.ini'"
}

try {
    Set-Content -Path "$teradiciPath\Teradici PCoIP Client.ini" -Value $clientConfig -Force
}
catch {
    throw "Failed to Write to File '$teradiciPath\Teradici PCoIP Client.ini'"
}