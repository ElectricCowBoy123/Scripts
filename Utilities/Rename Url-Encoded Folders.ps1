# Function to decode URL-encoded strings
function Decode-Url {
    param (
        [string]$urlEncoded
    )
    return [System.Net.WebUtility]::UrlDecode($urlEncoded)
}

# Function to rename folders in a directory recursively
function Rename-UrlEncodedFolders {
    param (
        [string]$directory
    )

    # Get all folders in the directory and subdirectories
    Get-ChildItem -Path $directory -Recurse -Directory | ForEach-Object {
        $originalFolderPath = $_.FullName
        $decodedFolderName = Decode-Url -urlEncoded $_.Name
        $decodedFolderPath = Join-Path -Path $_.Parent.FullName -ChildPath $decodedFolderName

        # Check if the decoded folder name is not null or empty and is different from the original
        if (![string]::IsNullOrEmpty($decodedFolderName) -and $originalFolderPath -ne $decodedFolderPath) {
            Write-Host "Renaming Folder: $originalFolderPath to $decodedFolderPath"
            Rename-Item -Path $originalFolderPath -NewName $decodedFolderName
        } else {
            Write-Host "Skipping Folder: $originalFolderPath (decoded name is null, empty, or the same as original)"
        }
    }
}

# Function to rename files in a directory recursively
function Rename-UrlEncodedFiles {
    param (
        [string]$directory
    )

    # Get all files in the directory and subdirectories
    Get-ChildItem -Path $directory -Recurse -File | ForEach-Object {
        $originalFilePath = $_.FullName
        $decodedFileName = Decode-Url -urlEncoded $_.Name
        $decodedFilePath = Join-Path -Path $_.DirectoryName -ChildPath $decodedFileName

        # Check if the decoded file name is not null or empty and is different from the original
        if (![string]::IsNullOrEmpty($decodedFileName) -and $originalFilePath -ne $decodedFilePath) {
            Write-Host "Renaming File: $originalFilePath to $decodedFilePath"
            Rename-Item -Path $originalFilePath -NewName $decodedFileName
        } else {
            Write-Host "Skipping File: $originalFilePath (decoded name is null, empty, or the same as original)"
        }
    }
}

# Main function to process both folders and files
function Rename-UrlEncodedItems {
    param (
        [string]$directory
    )

    # Rename folders first
    Rename-UrlEncodedFolders -directory $directory

    # Rename files after folders
    Rename-UrlEncodedFiles -directory $directory
}

# Replace with the path to the directory you want to process
Rename-UrlEncodedItems -directory '\\TEST\Sources\Applications\Autodesk\Revit_2025_Content\x64\C\A\RVT\L\EM\UK\'
