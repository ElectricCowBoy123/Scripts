$date = (Get-Date).ToString("o")
$loggedInUser = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name  
$serviceAccountUser = "$($env:COMPUTERNAME)\svc_vpn"  
$serviceAccountPassword = "YourPassword" 
$taskName = "VPNSvc_"

$serviceAccountSID = (New-Object System.Security.Principal.NTAccount($serviceAccountUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value

$scheduledTaskString = @"
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>$($date)</Date>
    <Author>$loggedInUser</Author> <!-- Currently logged-in user -->
    <URI>\$taskName</URI>
  </RegistrationInfo>
  <Triggers>
    <BootTrigger>
      <Enabled>true</Enabled>
      <Delay>PT10S</Delay>
    </BootTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>$serviceAccountSID</UserId> <!-- Use the SID for the service account -->
      <LogonType>Password</LogonType> <!-- Specify Password logon type -->
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>false</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>false</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>true</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>false</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>false</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT0S</ExecutionTimeLimit>
    <Priority>7</Priority>
    <RestartOnFailure>
      <Interval>PT1M</Interval>
      <Count>3</Count>
    </RestartOnFailure>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>"C:\Program Files\OpenVPN\bin\openvpn-gui.exe"</Command>
      <Arguments>--connect "TEST.ovpn"</Arguments> #PRIVATE
    </Exec>
  </Actions>
</Task>
"@

$taskExists = Get-ScheduledTask | Where-Object { $_.TaskName -eq $taskName }

if (-not $taskExists) {
    Register-ScheduledTask -Xml $scheduledTaskString -TaskName $taskName -User $serviceAccountUser -Password $serviceAccountPassword
    Write-Host "Scheduled task '$taskName' has been created."
} else {
    Write-Host "Scheduled task '$taskName' already exists. No action taken."
}

if ($((Get-ScheduledTask -TaskName "$taskName") | Select-Object State) -notlike "*Running*"){
    if ($((Get-ScheduledTask -TaskName "VPNSvc") | Select-Object State) -like "*Running*"){
        Stop-ScheduledTask -TaskName "VPNSvc"
    }
    Unregister-ScheduledTask -TaskName "VPNSvc" -Confirm:$false
    Start-ScheduledTask -TaskName $taskName
    Write-Host "Scheduled task '$taskName' has been started."
}
else {
    Write-Host "'$taskName' is already running."
}


