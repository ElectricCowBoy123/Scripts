function Extract-Zip {
    ## Extract the .zip file
    try {
        Write-Host "Extracting Qualys .zip..."
        Expand-Archive -Path "$zipPath" -DestinationPath "$destinationPath" -Force
    }
    catch {
        throw "[Error]: Failed to Un-zip '$zipPath' Exception: $($_.Exception)"
    }
}

## Variables

$destinationPath = "$($env:SYSTEMDRIVE)\Windows\Temp\TEST\QualysCloudAgent"
#$InstallerLogFile = "$destinationPath\QualysCloudAgent.log"

if($($env:customerId).Length -le 0 -or $($env:activationId).Length -le 0){
    throw "[Error]: Please Supply a Value for customerID and activationID!"
}

if($($env:usePath).Length -le 0 -and $($env:zipPath).Length -le 0){
    throw "[Error]: Please Supply a Value for usePath and zipPath!"
}

if($($env:usePath).Length -le 0 -and $($env:downloadUrl).Length -le 0 -and $($env:zipPath).Length -le 0){
    throw "[Error]: Please Supply a Value for usePath, zipPath or downloadUrl!" 
}

if($($env:usePath).Length -gt 0 -and $($env:zipPath).Length -gt 0 -and $($env:downloadUrl).Length -le 0){
    try {
        Write-Host "Installing Qualys via Path..."
        [Switch]$usePath = [System.Convert]::ToBoolean($env:usePath)
    }
    catch {
        throw "[Error]: Please Provide a Valid Value for the 'usePath' parameter  Exception: $($_.Exception)"
    }
}

if($($env:zipPath).Length -le 0){
    $zipPath = "$($env:SYSTEMDRIVE)\Windows\Temp\TEST\QualysCloudAgent.zip"
}
else {
    $zipPath = $env:zipPath
}

if ($($env:downloadUrl).Length -gt 0 -and -not $usePath){
    $downloadURL = $env:downloadUrl

    if($downloadURL -notlike '*.zip' -and $downloadURL -notlike '*.exe'){
        throw "[Error]: URL is Invalid, Exception $($_.Exception)"
    }

    if($(Test-Path -Path "$zipPath")){
        Write-Host "'$zipPath' Already Exists, Deleting..."
        try {
            Remove-Item -Path "$zipPath" -Force
        }
        catch {
            throw "[Error]: Failed to Delete '$zipPath' Exception: $($_.Exception)"
        }
    }

    ## Download the Qualys Agent
    try {
        Write-Host "Downloading Qualys..."
        #$webClient = New-Object System.Net.WebClient
        #$webClient.DownloadFile($downloadURL, $zipPath)
        Invoke-WebRequest -Uri "$downloadURL" -OutFile "$zipPath"
    }
    catch {
        throw "[Error]: Failed to Download Qualys Agent '$downloadURL' Exception: $($_.Exception)"
    }

    if($downloadURL -like '*.zip'){
        Extract-Zip
    }
}

if(Test-Path -Path "$destinationPath"){
    Write-Host "'$destinationPath' Already Exists, Deleting..."
    try {
        Remove-Item -Path "$destinationPath" -Force -Recurse
    }
    catch {
        throw "[Error]: Failed to Delete '$destinationPath' Exception: $($_.Exception)"
    }
}

if($($env:usePath).Length -gt 0){
    Extract-Zip
}

## Extract the .msi file
try {
    Write-Host "Extracting Qualys .msi..."
    Start-Process cmd -ArgumentList "/c `"$destinationPath\QualysCloudAgent.exe`" ExtractMSI=64" -WorkingDirectory "$destinationPath"

}
catch {
    throw "[Error]: Failed to Extract .msi from '$destinationPath\QualysCloudAgent.exe' Exception: $($_.Exception)"
}

## Runs the Qualys Cloud Agent with Parameters
try {
    Write-Host "Installing Qualys..."
    #Start-Process -Wait cmd -ArgumentList "/c msiexec /i `"$destinationPath\CloudAgent_x64.msi`" CustomerId={$env:customerId} ActivationID={$env:activationId} WebServiceUri=https://qagpublic.qg2.apps.qualys.eu/CloudAgent/ /quiet /norestart" -PassThru
    Start-Process -FilePath "msiexec.exe" -ArgumentList "/i `"$destinationPath\CloudAgent_x64.msi`" CustomerId={$env:customerId} ActivationID={$env:activationId} WebServiceUri=https://qagpublic.qg2.apps.qualys.eu/CloudAgent/ /quiet /norestart" -PassThru -Wait
    Write-Host "The Qualys Cloud Agent has Installed Successfully."
}
catch {
    throw "[Error]: Failed to Install Qualys! Exception: $($_.Exception)"
}

## Delete Qualys Installation Files
try {
    Write-Host "Deleting Qualys Installation Files..."
    Remove-Item -Path "$destinationPath" -Force -Recurse
}
catch {
    throw "[Error]: Failed to Delete '$destinationPath' Exception: $($_.Exception)"
}