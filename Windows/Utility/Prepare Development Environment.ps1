$straSoftwareList = @(
    "Microsoft.VisualStudioCode",
    "7zip.7zip",
    "ApacheFriends.Xampp.8.2",
    "Google.Chrome",
    "OpenJS.NodeJS",
    "Notepad++.Notepad++",
    "PuTTY.PuTTY",
    "Git.Git",
    "Mozilla.Firefox",
    "WinSCP.WinSCP"
)

if ($null -eq $env:softwareList -or ($env:softwareList -split ',').Length -eq 0) {
    throw "Please supply a comma-separated list of software to be installed! $($_.Exception)"
}

$straSoftwareList = $env:softwareList -split ','

$obj = [System.Security.Principal.WindowsIdentity]::GetCurrent()

if($($obj.Name -like "NT AUTHORITY*") -eq $True){
    throw "This Script Must be Ran as a User! $($_.Exception)"
}

function Install-Software {
    param (
        [Parameter(Mandatory=$True)] 
        [array]$softwareList
    )
    Write-Host "Installing Software..."
    foreach($item in $softwareList){
        try {
            if($(& winget list --disable-interactivity --accept-source-agreements | Select-String -SimpleMatch "$item").Length -gt 0){
                Write-Host "'$item' is already Installed!"
            }
            else {
                try{
                    & winget install $item --disable-interactivity --accept-source-agreements
                }
                catch {
                    throw "Failed to Install '$item' via Winget! $($_.Exception)"
                }
                Write-Host "Installed '$item'"
            }
        }
        catch {
            throw "Failed to Determine if '$Item' is already Installed! $($_.Exception)"
        }
    }
}

$OSVersion = Get-WmiObject Win32_OperatingSystem | Select-Object BuildNumber

if($osVersion.BuildNumber -ge 22631){
    if($(Get-Command winget -ErrorAction SilentlyContinue).Length -gt 0){
        Install-Software -softwareList $straSoftwareList
    }
    else {
        throw "Winget is not Installed!"
    }
}
else {
    throw "Windows Version Less than 23H2! $($_.Exception)"
}