function Get-DetailedPowerSettings {
    $settings = @{}
    $currentScheme = $null
    $currentSubgroup = $null

    powercfg /query | ForEach-Object {
        if ($_ -match "Power Scheme GUID") {
            $currentScheme = ($_ -split "Power Scheme GUID: ")[1].Trim()
            if (-not [string]::IsNullOrWhiteSpace($currentScheme) -and -not $settings.ContainsKey($currentScheme)) {
                $settings[$currentScheme] = @{}
            }
        } elseif ($_ -match "Subgroup GUID") {
            $currentSubgroup = ($_ -split "Subgroup GUID: ")[1].Trim()
            if (-not [string]::IsNullOrWhiteSpace($currentSubgroup) -and -not $settings[$currentScheme].ContainsKey($currentSubgroup)) {
                $settings[$currentScheme][$currentSubgroup] = @()
            }
        } elseif ($_ -match "Power Setting GUID") {
            $powerSettingGUID = ($_ -split "Power Setting GUID: ")[1].Trim()
            if (-not [string]::IsNullOrWhiteSpace($powerSettingGUID)) {
                $currentSetting = @{
                    PowerSettingGUID = $powerSettingGUID
                    Minimum = $null
                    Maximum = $null
                    Units = $null
                    CurrentAC = $null
                    CurrentDC = $null
                    SettingIndex = @()
                    SettingFriendlyName = @()
                }
                $settings[$currentScheme][$currentSubgroup] += $currentSetting
            }
        } elseif ($_ -match "Minimum Possible Setting") {
            $minimum = ($_ -split "Minimum Possible Setting: ")[1].Trim()
            if (-not [string]::IsNullOrWhiteSpace($minimum)) {
                $currentSetting["Minimum"] = $minimum
            }
        } elseif ($_ -match "Maximum Possible Setting") {
            $maximum = ($_ -split "Maximum Possible Setting: ")[1].Trim()
            if (-not [string]::IsNullOrWhiteSpace($maximum)) {
                $currentSetting["Maximum"] = $maximum
            }
        } elseif ($_ -match "Possible Settings units") {
            $units = ($_ -split "Possible Settings units: ")[1].Trim()
            if (-not [string]::IsNullOrWhiteSpace($units)) {
                $currentSetting["Units"] = $units
            }
        } elseif ($_ -match "Current AC Power Setting Index") {
            $currentAC = ($_ -split "Current AC Power Setting Index: ")[1].Trim()
            if (-not [string]::IsNullOrWhiteSpace($currentAC)) {
                $currentSetting["CurrentAC"] = $currentAC
            }
        } elseif ($_ -match "Current DC Power Setting Index") {
            $currentDC = ($_ -split "Current DC Power Setting Index: ")[1].Trim()
            if (-not [string]::IsNullOrWhiteSpace($currentDC)) {
                $currentSetting["CurrentDC"] = $currentDC
            }
        } elseif ($_ -match "Possible Setting Index") {
            $settingIndex = ($_ -split "Possible Setting Index: ")[1].Trim()
            if (-not [string]::IsNullOrWhiteSpace($settingIndex)) {
                $currentSetting["SettingIndex"] += $settingIndex
            }
        } elseif ($_ -match "Possible Setting Friendly Name") {
            $friendlyName = ($_ -split "Possible Setting Friendly Name: ")[1].Trim()
            if (-not [string]::IsNullOrWhiteSpace($friendlyName)) {
                $currentSetting["SettingFriendlyName"] += $friendlyName
            }
        }
    }

    return $settings
}

$var = Get-DetailedPowerSettings

foreach ($scheme in $var.Keys) {
    $schemeName = $scheme.Substring(39, $scheme.Length - 40).Trim()
    Write-Host "# Current Power Plan: $($schemeName)" -ForegroundColor Cyan
    foreach ($subgroup in $var[$scheme].Keys) {
        $subgroupName = $subgroup.Substring(39, $subgroup.Length - 40).Trim()
        Write-Host "## Section: $($subgroupName)" -ForegroundColor Green
        foreach ($setting in $var[$scheme][$subgroup]) {
            $powerSettingGUIDName = $setting.PowerSettingGUID.Substring(39, $setting.PowerSettingGUID.Length - 40).Trim()
            Write-Host "### Setting: $($powerSettingGUIDName)" -ForegroundColor Yellow
            <#
            if (-not [string]::IsNullOrWhiteSpace($setting.Minimum)) {
                $minimumDecimal = [convert]::ToInt32($setting.Minimum, 16)
                Write-Host "Minimum Possible Setting: $minimumDecimal $($setting.Units)"
            }
            if (-not [string]::IsNullOrWhiteSpace($setting.Maximum)) {
                $maximumDecimal = [convert]::ToInt32($setting.Maximum, 16)
                Write-Host "Maximum Possible Setting: $maximumDecimal $($setting.Units)"
            }
            #>
            if (-not [string]::IsNullOrWhiteSpace($setting.CurrentAC) -and [string]::IsNullOrWhiteSpace($setting.SettingIndex)) {
                $currentACDecimal = [convert]::ToInt32($setting.CurrentAC, 16)
                Write-Host "- Current Charging Power Setting: $currentACDecimal $($setting.Units)"
            }
            if (-not [string]::IsNullOrWhiteSpace($setting.CurrentAC) -and -not [string]::IsNullOrWhiteSpace($setting.SettingIndex)) {
                $currentACDecimal = [convert]::ToInt32($setting.CurrentAC, 16)
                Write-Host "- Current Charging Power Setting: $($setting.SettingFriendlyName[$currentACDecimal])"
            }

            if (-not [string]::IsNullOrWhiteSpace($setting.CurrentDC) -and [string]::IsNullOrWhiteSpace($setting.SettingIndex)) {
                $currentDCDecimal = [convert]::ToInt32($setting.CurrentDC, 16)
                Write-Host "- Current Battery Power Setting: $currentDCDecimal $($setting.Units)"
            }
            if (-not [string]::IsNullOrWhiteSpace($setting.CurrentDC) -and -not [string]::IsNullOrWhiteSpace($setting.SettingIndex)) {
                $currentDCDecimal = [convert]::ToInt32($setting.CurrentDC, 16)
                Write-Host "- Current Battery Power Setting: $($setting.SettingFriendlyName[$currentDCDecimal])"
            }

            Write-Host ""
        }
    }
}