if ((Get-LocalUser -Name "Administrator").Enabled -eq $False) {
    try {
        $strSerial = ((Get-WmiObject -Query 'select * from SoftwareLicensingService').OA3xOriginalProductKey -Split '-')[0]
        Write-Host "Serial: $($strSerial)"
        Write-Host "Remember to prepend 'TST-'" #PRIVATE
        $strUsername = "Administrator"
        Set-LocalUser -Name $strUsername -PasswordNeverExpires $True -Password (ConvertTo-SecureString -String $("TST-" + $strSerial) -AsPlainText -Force)
    }
    catch {
        throw "[Error] Exception occurred changing local administrator password: $($_.Exception.Message)"
    }
}