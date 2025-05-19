$Revit2023reg = Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{205C6D76-2023-2057-B227-DC6376F702DC}"
$Revit2025reg = Test-Path -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\{8A24E9A1-C48F-3F77-8464-E0544D5FB778}"

if(-not $Revit2023reg -or -not $Revit2025reg){
	$strActiveUser = Get-WmiObject -Query "SELECT * FROM Win32_ComputerSystem" | Select-Object -ExpandProperty UserName
	if($null -ne $strActiveUser){
	    Start-Process -FilePath "\\TEST\Sources\Applications\Autodesk\Revit_2025_Content\Setup.exe" -ArgumentList "--silent" -Wait
	    Start-Process -FilePath "\\TEST\Sources\Applications\Autodesk\Revit_2023_Content\Setup.exe" -ArgumentList "--silent" -Wait
	} else {
	    Write-Host "No Logged in User!"
	}
} else {
    Write-Host "Content is already installed"
}