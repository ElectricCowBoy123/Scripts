$logName = "Application"
Get-WinEvent -LogName "Application" | Where-Object { $_.Message -like "*$env:searchString*" }