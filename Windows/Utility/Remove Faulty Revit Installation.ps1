function Remove-RegKey($uninstallKeys){
	foreach ($key in $uninstallKeys) {
		foreach ($objRegKey in Get-ItemProperty $key) {
			if ($objRegKey.DisplayName -eq "Autodesk Revit 2025" -or $objRegKey.DisplayName -eq "Revit 2025") {
				$fullPath = $objRegKey.PSPath
				Write-Host "Software not Installed but Registry Key Exists! Removing..."
				Remove-Item -Path $objRegKey.PSPath -Force
				$noReg = 1
			}
		}
	}
}

function Get-RegKey(){
	foreach ($key in $uninstallKeys) {
		foreach ($objRegKey in Get-ItemProperty $key) {
			if ($objRegKey.DisplayName -eq "Autodesk Revit 2025" -or $objRegKey.DisplayName -eq "Revit 2025") {
				return "Registry Key Found"
				#$objRegKey.PSPath
			}
		}
	}
	return "Can't find Registry Key"
}

function Get-InstallStatus(){
	$process = Get-Process -Name "Installer.exe" -ErrorAction SilentlyContinue
	if ($process) {
		return $True
	} else {
		return $False
	}
}

$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
if($strActiveUser -ne $null){
	$strUserSID = (New-Object System.Security.Principal.NTAccount($strActiveUser)).Translate([System.Security.Principal.SecurityIdentifier]).Value
	$uninstallKeys = @(
		"HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
		"HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
		"Registry::HKEY_USERS\$strUserSID\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
	)
}
else {
	$uninstallKeys = @(
		"HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*",
		"HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*",
		"HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*"
	)
}

if(Test-Path -Path "C:\Program Files\Autodesk\Revit 2025"){
	if((Get-ChildItem -Path "C:\Program Files\Autodesk\Revit 2025" -Name "Revit.exe") -and (Get-ChildItem -Path "C:\Program Files\Autodesk\Revit 2025" -Name "RevitWorker.exe")){
		Write-Host "Executables Present"
		if(Get-InstallStatus){
			Write-Host "SCCM is Currently Installing This."
		}
		Write-Host $(Get-RegKey)
	}
	else {
		if(Get-InstallStatus){
			Write-Host "SCCM is Currently Installing This."
		}
		else {
			Write-Host "Issue with the software!"
			Remove-RegKey($uninstallKeys)
			Remove-Item -Path "C:\Program Files\Autodesk\Revit 2025" -Force -Recurse
		}
		
	}
}
else {
	$noReg = 0
	Remove-RegKey($uninstallKeys)
	if($noReg -eq 0){
	  Write-Host "Software not Installed!"
	}
}

