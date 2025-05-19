$Control = Get-ChildItem -Path "C:\Program Files (x86)\" -Recurse -Filter "*ScreenConnect Client*" -ErrorAction SilentlyContinue
Write-Host "Screen Connect (Instance URLs):"
if($Control){
    foreach($controlInstance in $Control.Name){
        $configPath = Join-Path -Path "C:\Program Files (x86)\$($controlInstance)" -ChildPath "system.config"
        if (Test-Path $configPath) {
            [xml]$controlConfig = Get-Content $configPath
            $valueNode = $controlConfig.SelectSingleNode("//configuration/ScreenConnect.ApplicationSettings/setting/value")
            $result = $valueNode.InnerText -split "&p", 2 | Select-Object -First 1
            $result = $result -split "\?h=", 2 | Select-Object -Last 1
            if ($valueNode) {
                Write-Host "$($result)"
            }
        }
    }
}
else {
    Write-Host "Screen Connect not Installed."
}

$BD = Get-ChildItem -Path "C:\Program Files\" -Recurse -Filter "Bitdefender" -ErrorAction SilentlyContinue
Write-Host "`nBitDefender (Support Information):"
if($BD){
    foreach($bitDefenderInstance in $BD.Name){
        $configPath = Join-Path -Path "C:\Program Files\$($bitDefenderInstance)\Endpoint Security\settings\system" -ChildPath "Product.Configuration.General.conf"
        if (Test-Path $configPath) {
            $jsonContent = Get-Content -Path $configPath -Raw | ConvertFrom-Json
            $technicalSupport = $jsonContent."Product.Configuration.General".technicalSupport
            if($($technicalSupport.email).Length -gt 0){
                $email = $technicalSupport.email -split "@", 2 | Select-Object -Last 1
            }
            if($($technicalSupport.website).Length -gt 0){
                $website = $technicalSupport.website -split "https://", 2 | Select-Object -Last 1
                $website = $website -split "/", 2 | Select-Object -First 1
            }
            if($null -ne $website -and $null -ne $email){
                Write-Host $website
            }
            elseif($null -ne $email){
                Write-Host $email
            }
            elseif($null -ne $website){
                Write-Host $website
            }
            else {
                Write-Host "No details found in the configuration file."
            }
        }
    }
}
else {
    Write-Host "BitDefender not Installed."
}
