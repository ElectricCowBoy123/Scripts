Get-Printer | ForEach-Object {
    if($_.Name -like '*Fax*' -or $_.Name -like '*OneNote*'){
        Write-Host "Removing Printer $($_.Name)"
        Remove-Printer -Name $_.Name
    }
}