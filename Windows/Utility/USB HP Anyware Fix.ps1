$serviceName = "fusbhub"
$service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue

if ($service) {
    if ($service.Status -eq "Stopped") {
        Start-Service -Name $serviceName
    }
    Set-Service -Name $serviceName -StartupType Automatic
    Write-Host "Service '$serviceName' started and set to Automatic.`n"
} else {
    Write-Output "Service '$serviceName' not found."
}

$cmdPath = "C:\Program Files\Sophos\AutoUpdate\SAUcli.exe"
if (Test-Path $cmdPath) {
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"`"$cmdPath`" UpdateNow`"" -NoNewWindow -Wait
    Write-Host "Sophos AutoUpdate executed successfully.`n"
} else {
    Write-Output "Sophos AutoUpdate executable not found at '$cmdPath'."
}