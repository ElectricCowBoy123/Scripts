# Define the list of applications to check and potentially remove

$strHTApps = @(
    # Microsoft Apps
    "Dev Home",
    "Health Check",
    "Get Help",
    "Microsoft Tips",
    "Paint 3D",
    "Quick Assist",
    "3D Builder",                                 
    "Appconnector",
    "Bing",                                  
    "Comms Phone",
    "Connectivity Store",
    "3D Viewer",
    "Solitaire", 
    "Mixed Reality",
    "Speed Test",            
    "Sway",
    "OneConnect",              
    "People",                             
    "Print 3D",                     
    "Skype",                     
    "Todos",                       
    "Wallet",
    "Whiteboard",                  
    "Feedback Hub",          
    "Maps",                  
    "Windows Phone",
    "Reading List",
    "Microsoft.WindowsSoundRecorder",
    "Xbox",                     
    "Your Phone",                    
    "Zune",                                    
    "Advertising",
    "Clipchamp",
    "GetStarted",		     
    "WebExperience",  
    "Teams",
    # Other Apps
    "McAfee",
    "Dropbox",
    "Booking.com",
    "EMEA",
    "Eclipse",
    "Actipro",
    "Adobe",
    "Duolingo",
    "Pandora",
    "Candy Crush",
    "Bubble Witch Saga",
    "Wunderlist",
    "Flipboard",
    "Twitter",
    "Facebook",
    "Spotify",
    "Minecraft",
    "Royal Revolt",
    "Sway",
    "LinkedIn",
    "Speed Test",
    "Dolby"
)

[bool]$boolIsInGroup = $(Invoke-Expression "net localgroup administrators") -contains $(([System.Security.Principal.WindowsIdentity]::GetCurrent()).Name)

if (-not $boolIsInGroup) {
    throw "Please run this as an administrator!"
} 

foreach ($strApp in $strHTApps) {
    # Get installed applications that match the name
    $installedApps = Get-AppxPackage | Where-Object { $_.Name -like "*$strApp*" }

    foreach ($installedApp in $installedApps) {
        if ($installedApp) {
            Write-Host "Removing application: $($installedApp.PackageFullName)"
            Remove-AppxPackage -Package $installedApp.PackageFullName -Force
        }
    }
}