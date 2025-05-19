New-Variable -Name 'gBoolHasRun' -Value $False -Scope Global
$global:flag = $False

#region Function Declarations
function funcSetRegistryFlags(){
    param(
        [Parameter(Mandatory = $True)]
        [String]$strPath
    )

    if(-not (Test-Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -ErrorAction SilentlyContinue)){
        Write-Host "[Informational] $strPath is not an actual Windows user, skipping..."
        Set-Variable -Name 'gBoolHasRun' -Value $False -Scope Global
        return # Hive is not an actual Windows user
    } #PRIVATE
    if (Test-Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -ErrorAction SilentlyContinue) {
        if (-not (Test-Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -ErrorAction SilentlyContinue)) {
            New-Item -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Force
        }
    }

    Set-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name "BT" -Value "0" -Type "String" -ErrorAction SilentlyContinue -Force
    Set-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name "DO" -Value "1" -Type "String" -ErrorAction SilentlyContinue -Force
    Set-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name "CT" -Value "1" -Type "String" -ErrorAction SilentlyContinue -Force
    Set-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name "CL" -Value "0" -Type "String" -ErrorAction SilentlyContinue -Force
    Set-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name "TI" -Value "1" -Type "String" -ErrorAction SilentlyContinue -Force
    Set-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name "CVL" -Value "0" -Type "String" -ErrorAction SilentlyContinue -Force
    Set-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name "END" -Value "0" -Type "String" -ErrorAction SilentlyContinue -Force
    Set-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name "DPS" -Value "0" -Type "String" -ErrorAction SilentlyContinue -Force
    Set-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name "RDI" -Value "1" -Type "String" -ErrorAction SilentlyContinue -Force
    Set-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name "SDI" -Value "1" -Type "String" -ErrorAction SilentlyContinue -Force
    Set-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name "CDBG" -Value "1" -Type "String" -ErrorAction SilentlyContinue -Force
    Set-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name "SBE" -Value "1" -Type "String" -ErrorAction SilentlyContinue -Force   

    Set-Variable -Name 'gBoolHasRun' -Value $True -Scope Global
}

function funcRemoveRegistryFlags(){
    param(
        [Parameter(Mandatory = $True)]
        [String]$strPath
    )

    if (Test-Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -ErrorAction SilentlyContinue) {
        if ((Test-Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -ErrorAction SilentlyContinue)) {
            Remove-Item -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Force -Recurse
            Set-Variable -Name 'gBoolHasRun' -Value $True -Scope Global
        }
    }
}
#endregion
#region Logic
foreach ($objSubKey in $(Get-ChildItem -Path "Registry::HKEY_USERS")) {
    if ($objSubKey.Name -like "*S-1*" -and $objSubKey.Name -notlike "*Classes*") {
        funcSetRegistryFlags("Registry::$($objSubKey.Name)")
        if($global:gBoolHasRun){
            Write-Host "[Informational] Successful: $($objSubKey.Name)"
            $global:flag = $True
        }
    }
}
if(!$global:flag){
    throw "[Error] Script didn't run for any users!"
}
#endregion