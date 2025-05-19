$thumbPrint = $env:thumbprint
Get-ChildItem -Path Cert:\LocalMachine\Root | Where-Object { $_.Thumbprint -like "*$thumbPrint*" }