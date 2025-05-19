function funcGetRegistryFlags(){
    param(
        [Parameter(Mandatory = $True)]
        [String]$path
    )

    if (Test-Path "$path\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon" -ErrorAction SilentlyContinue) {
        if ((Test-Path "$path\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -ErrorAction SilentlyContinue)) {

            $registryFlags = @{
                #BT = $(Get-ItemProperty -Path "$path\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'BT').BT
                DO = $(Get-ItemProperty -Path "$path\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'DO').DO
                CT = $(Get-ItemProperty -Path "$path\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'CT').CT
                #CL = $(Get-ItemProperty -Path "$path\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'CL').CL
                TI = $(Get-ItemProperty -Path "$path\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'TI').TI
                #CVL = $(Get-ItemProperty -Path "$path\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'CVL').CVL
                #END = $(Get-ItemProperty -Path "$path\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'END').END
                #DPS = $(Get-ItemProperty -Path "$path\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'DPS').DPS
                RDI = $(Get-ItemProperty -Path "$path\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'RDI').RDI
                SDI = $(Get-ItemProperty -Path "$path\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'SDI').SDI
                CDBG = $(Get-ItemProperty -Path "$path\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'CDBG').CDBG
                SBE = $(Get-ItemProperty -Path "$path\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Winlogon\TST" -Name 'SBE').SBE
            } 

            if($registryFlags['DO'] -eq '1'){
                Write-Host "DO = 1"
            } 
            if($registryFlags['DO'] -eq '0'){
                throw "DO = 0"
            } 

            if($registryFlags['CT'] -eq '1'){
                Write-Host "CT = 1"
            } 
            if($registryFlags['CT'] -eq '0'){
                throw "CT = 0"
            }

            if($registryFlags['TI'] -eq '1'){
                Write-Host "TI = 1"
            }
            if($registryFlags['TI'] -eq '0'){
                throw "TI = 0"
            }

            if($registryFlags['RDI'] -eq '1'){
                Write-Host "RDI = 1"
            }
            if($registryFlags['RDI'] -eq '0'){
                throw "RDI = 0"
            }
        
        
            if($registryFlags['SDI'] -eq '1'){
                Write-Host "SDI = 1"
            }
            if($registryFlags['SDI'] -eq '0'){
                throw "SDI = 0"
            }
            
        
            if($registryFlags['CDBG'] -eq '1'){
                Write-Host "CDBG = 1"
            }
            if($registryFlags['CDBG'] -eq '0'){
                throw "CDBG = 0"
            }
            
        
            if($registryFlags['SBE'] -eq '1'){
                Write-Host "SBE = 1"
            }
            if($registryFlags['SBE'] -eq '0'){
                throw "SBE = 0"
            }
        }
        else {
            throw "TST DOESN'T EXIST!"
        }
    }
}

try{
    # Execute the query and retrieve the active user session
    $activeUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
    # Get the SID (Security Identifier) of the active user
    $userSID = (New-Object System.Security.Principal.NTAccount($activeUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
}
catch {
    throw "Error getting the userSID or querying for the current user!"
}

funcGetRegistryFlags("Registry::HKEY_USERS\$userSID")