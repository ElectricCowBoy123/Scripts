$users = Get-WmiObject Win32_UserProfile | Where-Object { $_.Special -eq $false }
$results = @()
foreach ($user in $users) {
    $username = $user.LocalPath.Split('\')[-1] 
    $lastLogon = $user.LastUseTime 
    $localPath = $user.LocalPath
    $machineName = $user.__SERVER
    
    if ($lastLogon) {
        $lastLogonDateTime = [Management.ManagementDateTimeConverter]::ToDateTime($lastLogon)
    } else {
        $lastLogonDateTime = 0
    }

    $results += [PSCustomObject]@{
        Username     = $username
        LastLogon    = $lastLogonDateTime
        LocalPath    = $localPath
        MachineName  = $machineName
    }
}

$results | Format-Table -AutoSize

foreach($account in $results){
    $missingProfile = 0
    if($account.LastLogon -eq 0){
        Write-Host "Account $($account.Username) Has Last Logon Time 0! Using Fallback Method"
        Write-Host "Profile Path $($account.LocalPath)"
        if (Test-Path -Path $account.LocalPath) {
            Write-Host "New Value: $($(Get-Item -Path $account.LocalPath).LastWriteTime)"
        }
        else {
            Write-Host "Profile $($account.LocalPath) Doesn't Exist! Skipping..."
            $missingProfile = 1
        }
    }
    if($missingProfile -ne 1){
        $timeDifference = $(Get-Date) - $account.LastLogon 
        Write-Host "Time Difference: $($timeDifference.Days) (Days)"
        if($account.Username -ne 'admin' -and $account.Username -notlike '*svc*' -and $timeDifference.Days -gt 80){
            Write-Host "Deleting Old Profile: $($account.Username)"
            Write-Host "Deleting Path '$($account.LocalPath)'"
            Remove-Item -Path $account.LocalPath -Force -Recurse -Confirm:$False
        }
    }
}