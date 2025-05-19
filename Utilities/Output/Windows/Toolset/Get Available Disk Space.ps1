$disks = Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType=3"
$diskInfo = @()

foreach ($disk in $disks) {
    $driveTypeName = switch ($disk.DriveType) {
        0 { "Unknown" }
        1 { "No Root Directory" }
        2 { "Removable Disk" }
        3 { "Local Disk" }
        4 { "Network Drive" }
        5 { "Compact Disc" }
        6 { "RAM Disk" }
        Default { "Other" }
    }
    $physicalDrive = Get-WmiObject -Class Win32_DiskDrive | Where-Object { $_.DeviceID -eq $disk.DeviceID.Replace(":", "") }
    $smartStatus = "Unknown"
    $driveCaption = "N/A"

    if ($physicalDrive) {

        $driveCaption = $physicalDrive.Caption

        if ($physicalDrive.SmartStatus -eq 1) {
            $smartStatus = "OK"
        } else {
            $smartStatus = "Fail"
        }
    }

    $diskInfo += [PSCustomObject]@{
        Drive          = $disk.DeviceID
        VolumeName     = $disk.VolumeName
        FileSystem     = $disk.FileSystem
        UsedSpace      = [math]::round(($disk.Size - $disk.FreeSpace) / 1GB, 2)  
        FreeSpace      = [math]::round($disk.FreeSpace / 1GB, 2)  
        TotalSpace     = [math]::round($disk.Size / 1GB, 2) 
        PercentFree    = [math]::round(($disk.FreeSpace / $disk.Size) * 100, 2)  
        VolumeSerial   = $disk.VolumeSerialNumber
        DriveType      = $driveTypeName
        ProviderName   = $disk.ProviderName
        LastErrorCode  = $disk.LastErrorCode
        MediaType      = $disk.MediaType
        Size           = [math]::round($disk.Size / 1GB, 2)
        FreeSpaceBytes = $disk.FreeSpace
        UsedSpaceBytes = $disk.Size - $disk.FreeSpace
        SmartStatus    = $smartStatus
    }
}

foreach ($info in $diskInfo) {
    Write-Host "----------------------------------------"
    Write-Host "Volume Letter: $($info.Drive)"
    Write-Host "Volume Name: $($info.VolumeName)"
    Write-Host "File System: $($info.FileSystem)"
    Write-Host "Used Space (GB): $($info.UsedSpace)"
    Write-Host "Free Space (GB): $($info.FreeSpace)"
    Write-Host "Total Space (GB): $($info.TotalSpace)"
    Write-Host "Percent Free: $($info.PercentFree)%"
    Write-Host "Volume Serial: $($info.VolumeSerial)"
    Write-Host "Drive Type: $($info.DriveType)"
    Write-Host "Provider Name: $($info.ProviderName)"
    Write-Host "Last Error Code: $($info.LastErrorCode)"
    Write-Host "Media Type: $($info.MediaType)"
    Write-Host "Size (GB): $($info.Size)"
    Write-Host "Free Space (Bytes): $($info.FreeSpaceBytes)"
    Write-Host "Used Space (Bytes): $($info.UsedSpaceBytes)"
    Write-Host "S.M.A.R.T. Status: $($info.SmartStatus)"
}
Write-Host "----------------------------------------"
