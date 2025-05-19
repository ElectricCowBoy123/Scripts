$TenantGUID = $env:365TenantId
$HKLMregistryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive'##Path to HKLM keys.
$DiskSizeregistryPath = 'HKLM:\SOFTWARE\Policies\Microsoft\OneDrive\DiskSpaceCheckThresholdMB'##Path to max disk size key.


if(!(Test-Path $HKLMregistryPath)){New-Item -Path $HKLMregistryPath -Force}
if(!(Test-Path $DiskSizeregistryPath)){New-Item -Path $DiskSizeregistryPath -Force}


##Silently sign in users to the OneDrive sync app with their Windows credentials.
New-ItemProperty -Path $HKLMregistryPath -Name 'SilentAccountConfig' -Value '1' -PropertyType DWORD -Force | Out-Null ##Enable silent account configuration.
New-ItemProperty -Path $DiskSizeregistryPath -Name $TenantGUID -Value '102400' -PropertyType DWORD -Force | Out-Null ##Set max OneDrive threshold before prompting.


##Coauthor and share in Office desktop apps.
#[HKCU\SOFTWARE\Policies\Microsoft\OneDrive] "EnableAllOcsiClients"=dword:00000001
New-ItemProperty -Path $HKLMregistryPath -Name 'EnableAllOcsiClients' -Value '1' -PropertyType DWORD -Force | Out-Null ##Enable coauthor and share in Office desktop apps.


##Silently move Windows known folders to OneDrive.
#[HKLM\SOFTWARE\Policies\Microsoft\OneDrive]"KFMSilentOptIn"="1111-2222-3333-4444"
New-ItemProperty -Path $HKLMregistryPath -Name 'KFMSilentOptIn' -Value '1' -PropertyType DWORD -Force | Out-Null ##Enable coauthor and share in Office desktop apps.

#[HKLM\SOFTWARE\Policies\Microsoft\OneDrive]"KFMSilentOptInWithNotification"=dword:00000001
New-ItemProperty -Path $HKLMregistryPath -Name 'KFMSilentOptInWithNotification' -Value '1' -PropertyType DWORD -Force | Out-Null ##Enable coauthor and share in Office desktop apps.

#[HKLM\SOFTWARE\Policies\Microsoft\OneDrive]"KFMSilentOptInDesktop"=dword:00000001: Setting this value to 1 will move the Desktop folder.
New-ItemProperty -Path $HKLMregistryPath -Name 'KFMSilentOptInDesktop' -Value '1' -PropertyType DWORD -Force | Out-Null ##Enable coauthor and share in Office desktop apps.

#[HKLM\SOFTWARE\Policies\Microsoft\OneDrive]"KFMSilentOptInDocuments"=dword:00000001: Setting this value to 1 will move the Documents folder.
New-ItemProperty -Path $HKLMregistryPath -Name 'KFMSilentOptInDocuments' -Value '1' -PropertyType DWORD -Force | Out-Null ##Enable coauthor and share in Office desktop apps.

#[HKLM\SOFTWARE\Policies\Microsoft\OneDrive]"KFMSilentOptInPictures"=dword:00000001: Setting this value to 1 will move the Pictures folder.
New-ItemProperty -Path $HKLMregistryPath -Name 'KFMSilentOptInPictures' -Value '1' -PropertyType DWORD -Force | Out-Null ##Enable coauthor and share in Office desktop apps.


##Disable the tutorial that appears at the end of OneDrive Setup
#[HKCU\SOFTWARE\Policies\Microsoft\OneDrive] "DisableTutorial"=dword:00000001
New-ItemProperty -Path $HKLMregistryPath -Name 'DisableTutorial' -Value '1' -PropertyType DWORD -Force | Out-Null ##Enable coauthor and share in Office desktop apps.


##Prevent users from redirecting their Windows known folders to their PC
#[HKLM\SOFTWARE\Policies\Microsoft\OneDrive]"KFMBlockOptOut"=dword:00000001
New-ItemProperty -Path $HKLMregistryPath -Name 'KFMBlockOptOut' -Value '1' -PropertyType DWORD -Force | Out-Null ##Enable coauthor and share in Office desktop apps.


#----------------------------------------------------------------------------------------------------------------


##Configure team site libraries to sync automatically
#[HKCU\Software\Policies\Microsoft\OneDrive\TenantAutoMount]"LibraryName"="LibraryID"
$LibraryName = '' 
$LibraryID = ''
#(tenantId=xxx&siteId=xxx&webId=xxx&listId=xxx&webUrl=httpsxxx&version=1)


##Use OneDrive Files On-Demand
#[HKLM\SOFTWARE\Policies\Microsoft\OneDrive]"FilesOnDemandEnabled"=dword:00000001
New-ItemProperty -Path $HKLMregistryPath -Name 'FilesOnDemandEnabled' -Value '1' -PropertyType DWORD -Force | Out-Null ##Enable coauthor and share in Office desktop apps.


#----------------------------------------------------------------------------------------------------------------


##Decrease the 8-hour delay to sync SHarepoint sites.

#Check for required QWord.
$Path = "HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts\Business1"
$Name = "TimerAutoMount"
$Type = "QWORD"
$Value = 1

Try {
    $Registry = Get-ItemProperty -Path $Path -Name $Name -ErrorAction Stop | Select-Object -ExpandProperty $Name
    If ($Registry -eq $Value){
        Write-Output "Compliant"
        Exit 0
    } 
    Write-Warning "Not Compliant"
    Exit 1
} 
Catch {
    Write-Warning "Not Compliant"
    Exit 1
}


#Remediation if not present.
$Path = "HKCU:\SOFTWARE\Microsoft\OneDrive\Accounts\Business1"
$Name = "TimerAutoMount"
$Type = "QWORD"
$Value = 1

Set-ItemProperty -Path $Path -Name $Name -Type $Type -Value $Value 