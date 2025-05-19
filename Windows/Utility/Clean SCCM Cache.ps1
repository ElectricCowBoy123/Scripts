$ccmCachePath = "C:\Windows\ccmcache"

if (Test-Path -Path $ccmCachePath) {
    try {
        Remove-Item -Path $ccmCachePath -Recurse -Force
        Write-Host "The ccmcache folder was successfully removed."
    } catch {
        Write-Host "An error occurred while trying to remove the ccmcache folder: $_"
    }
} else {
    Write-Host "The ccmcache folder does not exist."
}