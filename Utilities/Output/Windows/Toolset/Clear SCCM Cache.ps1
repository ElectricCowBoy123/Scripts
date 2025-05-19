$cachePath = "C:\Windows\ccmcache"
$items = Get-ChildItem -Path $cachePath -Recurse -Force

foreach ($item in $items) {
    try {
        Remove-Item -Path $item.FullName -Recurse -Force -ErrorAction Stop
        Write-Host "Deleted: $($item.FullName)"
    } catch {
        Write-Host "Failed to delete: $($item.FullName) - $_"
    }
}

Write-Host "SCCM cache cleared successfully."
