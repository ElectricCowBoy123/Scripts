$url = "https://download.bitdefender.com/SMB/Hydra/release/bst_win/uninstallTool/BEST_uninstallTool.exe"
$dir = "$($env:SYSTEMDRIVE)\TEST" #PRIVATE
$exeName = "BEST_uninstallTool.exe"
$fullPath = Join-Path -Path $dir -ChildPath $exeName
$password = ""

if (-Not (Test-Path -Path $dir)) {
    New-Item -ItemType Directory -Path $dir
}

Invoke-WebRequest -Uri $url -OutFile $fullPath

Start-Process -FilePath $fullPath -ArgumentList "/bdparams", "/password=$password" -Wait

if ($LASTEXITCODE -eq 0) {
    Write-Host "The program ran successfully."
} else {
    Write-Host "The program encountered an error. Exit code: $LASTEXITCODE"
}

Remove-Item -Path $fullPath -Force

Write-Host "The executable has been deleted."
