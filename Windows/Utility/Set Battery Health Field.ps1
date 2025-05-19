if($(Get-WmiObject -Class Win32_ComputerSystem).PCSystemType-eq 1){
    $isDesktop = $True
    $healthScore = 0
}

if(-not $isDesktop){
    if (-Not(Test-Path "$($env:SYSTEMDRIVE)\TEST\" )) {
        try {
            New-Item -Path "$($env:SYSTEMDRIVE)\TEST\" -ItemType Directory | Out-Null
        } #PRIVATE
        catch {
            throw "[Error] Failed to Create Directory $($env:SYSTEMDRIVE)\TEST\ $($_.Exception)"
        }
    }
    
    try {
        & powercfg /batteryreport /output "$($env:SYSTEMDRIVE)\TEST\battery-report.html"
    }
    catch {
        throw "[Error] Failed to Generate Report $($_.Exception)"
    }
    
    try {
        $htmlContent = Get-Content -Path "$($env:SYSTEMDRIVE)\TEST\battery-report.html" -Raw
        $designCapacity = [regex]::Match($htmlContent, '<span class="label">DESIGN CAPACITY</span></td><td>(\d{1,3}(,\d{3})*) mWh').Groups[1].Value
        $fullChargeCapacity = [regex]::Match($htmlContent, '<span class="label">FULL CHARGE CAPACITY</span></td><td>(\d{1,3}(,\d{3})*) mWh').Groups[1].Value
    }
    catch{
        throw "[Error] Failed to Manipulate Battery Information $($_.Exception)"
    }
    
    if($null -eq $designCapacity -or $null -eq $fullChargeCapacity){
        throw "[Error] Failed to Retrieve Battery Information"
    }
    
    $healthScore = $([math]::Ceiling(($fullChargeCapacity / $designCapacity) * 100))
    
    Write-Host "Design Capacity: $designCapacity mWh"
    Write-Host "Full Charge Capacity: $fullChargeCapacity mWh"
    Write-Host "Health Score $healthScore%"
}

Write-Host "`nSetting Custom Field..."
if (-not (Test-Path "$($env:SYSTEMDRIVE)\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe")) {
    Write-Host "$($env:SYSTEMDRIVE)\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe Does not Exist. Cannot Modify Custom Field in NinjaRMM"
    exit 0
}

try {
    & "$($env:SYSTEMDRIVE)\ProgramData\NinjaRMMAgent\ninjarmm-cli.exe" set "batteryHealth" $healthScore
}
catch {
    throw "[Error] Failed to Set batteryHealth Score in NinjaRMM $($_.Exception)"
}