#region Declaration & Validation
# Check if registry flag key exists
if (-not (Test-Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST")) {
    New-Item -Path "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Force
}
  
$oldErrorActionPreference = $ErrorActionPreference
$ErrorActionPreference = 'SilentlyContinue'
try {
    [string]$strCTVal = (Get-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST' -Name 'CT').CT
} catch {
    $strCTVal = $null
}
$ErrorActionPreference = $oldErrorActionPreference
#endregion

#region Logic
if($strCTVal -ne '1'){
    Start-Process "$($env:SYSTEMDRIVE)\Windows\Resources\Themes\aero.theme"

    # Kill settings app after applying theme
    #Get-Process | Where-Object { $_.Name -eq "SystemSettings" } | Select-Object -First 1 | Stop-Process -Force

    if ((Get-LocalUser | Where-Object { $_.Enabled -eq $True }).Count -gt 1) {
        $objWMAProcs = Get-Process | Where-Object { $_.ProcessName -eq 'WWAHost' } -ErrorAction SilentlyContinue
        if($null -ne $objWMAProcs){
            foreach ($objWMAProc in $objWMAProcs) {
                & taskkill /pid $objWMAProc.Id /f
            }
        }
    }
    New-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon\TST' -Name 'CT' -PropertyType 'String' -Value '1' -ErrorAction SilentlyContinue
    exit 0
}
if($strCTVal -eq '1'){
    Write-Host "[Informational] Change theme Script Already Ran!"
    exit 0
}
#endregion