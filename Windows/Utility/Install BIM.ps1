function Move-BIM {
    $sourcePath = "\\10.60.1.22\Sources\Applications\Autodesk\BIM_Interoperablity_Tools_25"
    $destinationPath = "C:\Windows\ccmcache\BIM"

    if (-not (Test-Path $destinationPath)) {
        Write-Host "Creating Dir: $($destinationPath)"
        New-Item -ItemType Directory -Path $destinationPath -Force
    }

    $exeFiles = Get-ChildItem -Path $sourcePath -Filter "InteroperabilityTools_10_0_1_61774_2025.exe" -File -ErrorAction SilentlyContinue

    foreach ($file in $exeFiles) {
        $destinationFile = Join-Path -Path $destinationPath -ChildPath $file.Name
        Copy-Item -Path $file.FullName -Destination $destinationFile -Force
    }
}

$registryKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{B1D54B12-C3DF-33F2-960A-722559C127FA}"
$displayName = (Get-ItemProperty -Path $registryKeyPath -ErrorAction SilentlyContinue).DisplayName
Write-Host $displayName
if ($displayName -ne "Autodesk Interoperability Tools v10.0.1.61774 for Revit 2025") {
    Move-BIM
    $enplaceExePath = Get-ChildItem -Path "C:\Windows\ccmcache\" -Recurse -Filter "InteroperabilityTools_10_0_1_61774_2025.exe" -ErrorAction SilentlyContinue

    if ($enplaceExePath) {
        foreach($dir in $enplaceExePath.Directory){
            $exeDirectory = Join-Path -Path $dir -ChildPath "InteroperabilityTools_10_0_1_61774_2025.exe"
        
            Start-Process "$($exeDirectory)" -ArgumentList "-q" -Verb RunAs
        }
    } else {
        Write-Host "InteroperabilityTools_10_0_1_61774_2025.exe not found in C:\Windows\ccmcache\."
    }
} else {
    Write-Host "Registry key exists. Skipping installation."
}