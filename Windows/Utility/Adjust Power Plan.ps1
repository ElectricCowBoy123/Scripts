function Get-ActivePowerPlan {
    return powercfg /getactivescheme
}

function Set-PowerPlan {
    param (
        [string]$guid,
        [string]$name
    )
    powercfg -setactive $guid
    Write-Output "$($name) power plan set as active. GUID: $($guid)"
}

function Ensure-PowerPlan {
    param (
        [string]$schemeAlias,
        [string]$name
    )
    $powerPlans = powercfg /list
    if ($powerPlans -notmatch $name) {
        $output = powercfg -duplicatescheme $schemeAlias
        if ($output -match "Power Scheme GUID:\s*([\w-]+)") {
            $guid = $matches[1]
            Set-PowerPlan -guid $guid -name $name
        } else {
            Write-Error "Failed to extract GUID for $($name) power plan."
        }
    } else {
        if ($powerPlans -match "Power Scheme GUID:\s*([\w-]+)\s*\($($name)\)") {
            $guid = $matches[1]
            Set-PowerPlan -guid $guid -name $name
        } else {
            Write-Error "Failed to find $($name) power plan GUID."
        }
    }
}

Write-Host "Available Power Plans:"
Write-Host "1 = High Performance"
Write-Host "2 = Balanced"
Write-Host "0 = Power Saver"

if ($env:plan -eq "1") {
    Ensure-PowerPlan -schemeAlias SCHEME_MIN -name "High performance"
} elseif ($env:plan -eq "2") {
    Ensure-PowerPlan -schemeAlias SCHEME_BALANCED -name "Balanced"
} elseif ($env:plan -eq "0") {
    Ensure-PowerPlan -schemeAlias SCHEME_MAX -name "Power saver"
} else {
    throw "Please provide a valid option (0, 1, or 2)!"
}

$activePlan = Get-ActivePowerPlan
Write-Output "Active Power Plan: $($activePlan)"