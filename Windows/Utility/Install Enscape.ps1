function Move-Enscape {
    $sourcePath = "\\10.60.1.22\Sources\Applications\Enscape"
    $destinationPath = "C:\Windows\ccmcache\Enscape"

    if (-not (Test-Path $destinationPath)) {
        New-Item -ItemType Directory -Path $destinationPath -Force
    }

    Copy-Item -Path $sourcePath\* -Destination $destinationPath -Recurse -Force
}

function Install-Enscape($enplaceExePath) {
    foreach($dir in $enplaceExePath.Directory){
        $exeDirectory = Join-Path -Path $dir -ChildPath "Enscape-4.4.0.452.exe"
        
        $msiPath = Join-Path -Path $dir -ChildPath "Enscape.msi"

        $configFilePath = Join-Path -Path $dir -ChildPath "config.xml"

        Start-Process "C:\Windows\System32\msiexec.exe" -ArgumentList "/i `"$msiPath`" /quiet ACCEPTEULA=1 SKIPREQUIREMENTS=1 ALLUSERS=1 INSTALLLEVEL=0 ADDLOCAL=Enscape,Revit,SketchUp" -Verb RunAs
        Start-Process "$($exeDirectory)" -ArgumentList "-gui=0 -configFile=`"$configFilePath`" -quiet=1" -Verb RunAs
    }
}

$registryKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{DF1F5DD6-5ED4-4B80-9434-1E1486B7707B}"
$expectedVersion = "3.4.1.85781"

if (-not (Test-Path $registryKeyPath) -or (Get-ItemProperty -Path $registryKeyPath -Name DisplayVersion -ErrorAction SilentlyContinue).DisplayVersion -ne $expectedVersion) {
    Write-Host "Installing Enscape 3.4.1.85781..."
    $msiPath = Get-ChildItem -Path "C:\Windows\ccmcache\" -Recurse -Filter "Enscape.msi" -ErrorAction SilentlyContinue
    if($msiPath){
        foreach($dir in $msiPath.Directory){
            $configFilePath = Join-Path -Path $dir -ChildPath "config.xml"
            $msiPath = Join-Path -Path $dir -ChildPath "Enscape.msi"
            Start-Process "C:\Windows\System32\msiexec.exe" -ArgumentList "/i `"$msiPath`" /quiet ACCEPTEULA=1 SKIPREQUIREMENTS=1 ALLUSERS=1 INSTALLLEVEL=0 ADDLOCAL=Enscape,Revit,SketchUp" -Verb RunAs
        }
    } else {
        Move-Enscape
        Start-Sleep -Seconds 5
        foreach($dir in $enplaceExePath.Directory){
            $configFilePath = Join-Path -Path $dir -ChildPath "config.xml"
            $msiPath = Join-Path -Path $dir -ChildPath "Enscape.msi"
            Start-Process "C:\Windows\System32\msiexec.exe" -ArgumentList "/i `"$msiPath`" /quiet ACCEPTEULA=1 SKIPREQUIREMENTS=1 ALLUSERS=1 INSTALLLEVEL=0 ADDLOCAL=Enscape,Revit,SketchUp" -Verb RunAs
        }
    }
}
else {
    Write-Host "Registry key exists for 3.4.1.85781. Skipping installation."
}

$registryKeyPath = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Enscape"
$expectedVersion = "4.4.0.452"

if (-not (Test-Path $registryKeyPath) -or (Get-ItemProperty -Path $registryKeyPath -Name DisplayVersion -ErrorAction SilentlyContinue).DisplayVersion -ne $expectedVersion) {
    Write-Host "Installing Enscape 4.4.0.452..."
    $enplaceExePath = Get-ChildItem -Path "C:\Windows\ccmcache\" -Recurse -Filter "Enscape-4.4.0.452.exe" -ErrorAction SilentlyContinue
    if ($enplaceExePath) {
        Install-Enscape -enplaceExePath $enplaceExePath
    } else {
        Move-Enscape
        Start-Sleep -Seconds 5
        $enplaceExePath = Get-ChildItem -Path "C:\Windows\ccmcache\" -Recurse -Filter "Enscape-4.4.0.452.exe" -ErrorAction SilentlyContinue
        Install-Enscape -enplaceExePath $enplaceExePath
        Write-Host "Enscape-4.4.0.452.exe not found in C:\Windows\ccmcache\."
    }
}
else {
    Write-Host "Registry key exists for 4.4.0.452. Skipping installation."
}