#region Function Declarations
function funcGetRegistryFlags(){
    param(
        [Parameter(Mandatory = $True)]
        [String]$strPath
    )

    if (Test-Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -ErrorAction SilentlyContinue) {
        if ((Test-Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -ErrorAction SilentlyContinue)) { #PRIVATE
            $strARegistryFlags = @{
                #BT = $(Get-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'BT').BT
                DO = $(Get-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'DO').DO
                CT = $(Get-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'CT').CT
                #CL = $(Get-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'CL').CL
                TI = $(Get-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'TI').TI
                #CVL = $(Get-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'CVL').CVL
                #END = $(Get-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'END').END
                #DPS = $(Get-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'DPS').DPS
                RDI = $(Get-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'RDI').RDI
                SDI = $(Get-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'SDI').SDI
                CDBG = $(Get-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'CDBG').CDBG
                SBE = $(Get-ItemProperty -Path "$strPath\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'SBE').SBE
            } 

            if($strARegistryFlags['DO'] -eq '1'){
                Write-Host "[Informational] DO = 1"
            } 
            if($strARegistryFlags['DO'] -eq '0'){
                throw "[Error] DO = 0"
            } 

            if($strARegistryFlags['CT'] -eq '1'){
                Write-Host "[Informational] CT = 1"
            } 
            if($strARegistryFlags['CT'] -eq '0'){
                throw "[Error] CT = 0"
            }

            if($strARegistryFlags['TI'] -eq '1'){
                Write-Host "[Informational] TI = 1"
            }
            if($strARegistryFlags['TI'] -eq '0'){
                throw "[Error] TI = 0"
            }

            if($strARegistryFlags['RDI'] -eq '1'){
                Write-Host "[Informational] RDI = 1"
            }
            if($strARegistryFlags['RDI'] -eq '0'){
                throw "[Error] RDI = 0"
            }
        
        
            if($strARegistryFlags['SDI'] -eq '1'){
                Write-Host "[Informational] SDI = 1"
            }
            if($strARegistryFlags['SDI'] -eq '0'){
                throw "[Error] SDI = 0"
            }
            
        
            if($strARegistryFlags['CDBG'] -eq '1'){
                Write-Host "[Informational] CDBG = 1"
            }
            if($strARegistryFlags['CDBG'] -eq '0'){
                throw "[Error] CDBG = 0"
            }
            
        
            if($strARegistryFlags['SBE'] -eq '1'){
                Write-Host "[Informational] SBE = 1"
            }
            if($strARegistryFlags['SBE'] -eq '0'){
                throw "[Error] SBE = 0"
            }
        }
        else {
            throw "[Error] TST DOESN'T EXIST!"
        }
    }
}
#endregion

#region Logic
try{
    # Execute the query and retrieve the active user session
    $strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
    # Get the SID (Security Identifier) of the active user
    $strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
}
catch {
    throw "[Error] Error getting the userSID or querying for the current user!"
}

funcGetRegistryFlags("Registry::HKEY_USERS\$strUserSID")
#endregion