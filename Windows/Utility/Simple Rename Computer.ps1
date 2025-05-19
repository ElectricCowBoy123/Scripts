$newComputerName = $env:newComputerName

# Check if the new computer name is valid
if ($newComputerName -match '^[a-zA-Z0-9-]{1,15}$') {
    # Rename the computer
    Rename-Computer -NewName $newComputerName -Force

    # Inform the user that a restart is required
    Write-Host "The computer will be renamed to '$newComputerName'. A restart is required for the changes to take effect."
} else {
    Write-Host "Invalid computer name. Please ensure it is 1-15 characters long and contains only letters, numbers, or hyphens."
}