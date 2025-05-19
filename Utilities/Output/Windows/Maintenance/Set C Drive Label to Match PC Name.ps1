#Checks C Drive Label and renames to match PC name if not already.

#Script Variables
$CDriveLabel = Get-Volume -DriveLetter 'C' | % FileSystemLabel

# Confirm Script Variables.
Write-Output "List of Variables used in this script:"
Write-Output "Current C Drive Label = $CDriveLabel"
Write-Output "Current Computer Name = $env:computername"

#Check if Drive Label matches Computer Name.
if ("$CDriveLabel" -eq "$env:computername") {
  Write-Output "C Drive named correctly - $CDriveLabel"
}

else
{
  Write-Output "C Drive Label requires changing..."
  Set-Volume -DriveLetter 'C' -NewFileSystemLabel "$env:computername"
}

#Get New C Drive Label
$NewCDriveLabel = Get-Volume -DriveLetter 'C' | % FileSystemLabel

Write-Output "C Drive Label changed to $NewCDriveLabel"