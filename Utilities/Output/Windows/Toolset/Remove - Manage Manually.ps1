$processes = @(
    "ConnectWiseCrashHandler",
    "ConnectWiseManage",
    "ConnectWise"
)

foreach($process in $processes){
    $processobj = Get-Process -Name $process -ErrorAction SilentlyContinue

    if ($processobj) {
        try {
            Stop-Process -Name $process -Confirm:$False -Force
            Write-Host "Terminated: $process"
        } catch {
            Write-Host "[Error] Failed to terminate process: $process. Error: $($_.Exception.Message)"
        }
    } else {
        Write-Host "Process $process is not running."
    }
}

$uninstallKeys = @(
    "HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
    "HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
)

Write-Host "Removing registry keys..."
$boolRegKeyFound = $False
foreach ($key in $uninstallKeys) {
    if (Test-Path -Path $key) {
        foreach ($objRegKey in Get-ItemProperty -Path $key -ErrorAction SilentlyContinue) {
            if ($objRegKey.DisplayName -eq "ConnectWise Manage Client 64-bit") {
                try {
                    $boolRegKeyFound = $True
                    Remove-Item -Path $objRegKey.PSPath -Recurse -Confirm:$False -Force
                    Write-Host "Successfully removed registry key: $($objRegKey.PSPath)"
                } catch {
                    Write-Host "Failed to remove registry path: $($objRegKey.PSPath). Error: $($_.Exception.Message)"
                }
            }
        }
    } 
}
$boolDeletedFiles = $False

Write-Host "Deleting dir $($env:SYSTEMDRIVE)\Program Files\ConnectWise\..."
if(Test-Path -Path "$($env:SYSTEMDRIVE)\Program Files\ConnectWise\" ){
    try {
        $boolDeletedFiles = $True
        Remove-Item -Path "$($env:SYSTEMDRIVE)\Program Files\ConnectWise\" -Recurse -Confirm:$False -Force
    }
    catch {
        throw "Failed to delete dir $($_.Exception)"
    }
}

if(!$boolDeletedFiles -and !$boolRegKeyFound) {
    Write-Host "ConnectWise Manage is not Installed!"
    exit 0
}
if($boolDeletedFiles -and $boolRegKeyFound) {
    Write-Host "Successfully Uninstalled Manage"
    exit 0
}
if(!$boolRegKeyFound -and $boolDeletedFiles){
    Write-Host "Successfully Deleted Connectwise Manage Left-over Files, Successfully Uninstalled Manage"
    exit 0
}
if($boolRegKeyFound -and !$boolDeletedFiles){
    Write-Host "Successfully Deleted Connectwise Manage Left-over Registry Entries, Successfully Uninstalled Manage"
    exit 0
}