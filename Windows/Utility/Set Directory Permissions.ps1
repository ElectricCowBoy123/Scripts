function Set-Permissions(){
    
    param (
        [Parameter(Mandatory = $true)]
        [string]$directoryPath
    )

    #Write-Host "Processing directory: $directoryPath"

    #$userOrGroupToRemove = "TEST\TEST - Data Drive"
    $userOrGroupToAdd = "Administrators"
    $userOrGroupToAdd1 = "CREATOR OWNER"
    $userOrGroupToAdd2 = "SYSTEM"
    $userOrGroupToAdd3 = "TEST\TEST - Obsolete Folder Access" #PRIVATE
    $userOrGroupToAdd4 = "admin@TEST.co.uk"

    $accessRightsFullControl = [System.Security.AccessControl.FileSystemRights]::FullControl  # Specify the access rights you want to grant
    $accessRights = [System.Security.AccessControl.FileSystemRights]::Modify -bor [System.Security.AccessControl.FileSystemRights]::Synchronize

    # Check if the directory exists
    if (-Not (Test-Path $directoryPath)) {
        Write-Host "Directory does not exist: $directoryPath"
        exit
    }

    # Get the ACL for the specified directory
    $subAcl = Get-Acl $directoryPath
    #Write-Host "Current ACL for: $directoryPath"
    #$subAcl.Access | Format-Table -AutoSize

    # Create a new access rule for the user/group to add
    #$newRule = New-Object System.Security.AccessControl.FileSystemAccessRule($userOrGroupToAdd, $accessRights, "Allow")

    $inheritanceFlags = [System.Security.AccessControl.InheritanceFlags]::ContainerInherit -bor [System.Security.AccessControl.InheritanceFlags]::ObjectInherit

    $newRule = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $userOrGroupToAdd,
    $accessRightsFullControl,
    $inheritanceFlags,
    [System.Security.AccessControl.PropagationFlags]::None,
    [System.Security.AccessControl.AccessControlType]::Allow
    )
    

    #$newRule1 = New-Object System.Security.AccessControl.FileSystemAccessRule($userOrGroupToAdd1, $accessRights, "Allow")

    $newRule1 = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $userOrGroupToAdd1,
    $accessRightsFullControl,
    $inheritanceFlags,
    [System.Security.AccessControl.PropagationFlags]::None,
    [System.Security.AccessControl.AccessControlType]::Allow
    )
    
    #$newRule2 = New-Object System.Security.AccessControl.FileSystemAccessRule($userOrGroupToAdd2, $accessRights, "Allow")

    $newRule2 = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $userOrGroupToAdd2,
    $accessRightsFullControl,
    $inheritanceFlags,
    [System.Security.AccessControl.PropagationFlags]::None,
    [System.Security.AccessControl.AccessControlType]::Allow
    )


    #$newRule3 = New-Object System.Security.AccessControl.FileSystemAccessRule($userOrGroupToAdd3, $accessRights, "Allow")

    $newRule3 = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $userOrGroupToAdd3,
    $accessRights,
    $inheritanceFlags,
    [System.Security.AccessControl.PropagationFlags]::None,
    [System.Security.AccessControl.AccessControlType]::Allow
    )

    $newRule4 = New-Object System.Security.AccessControl.FileSystemAccessRule(
    $userOrGroupToAdd4,
    $accessRightsFullControl,
    $inheritanceFlags,
    [System.Security.AccessControl.PropagationFlags]::None,
    [System.Security.AccessControl.AccessControlType]::Allow
    )

    # Add the new access rule
    $subAcl.AddAccessRule($newRule)
    #Write-Host "Added permission: $accessRights for $userOrGroupToAdd"

    $subAcl.AddAccessRule($newRule1)
    #Write-Host "Added permission: $accessRights for $userOrGroupToAdd1"

    $subAcl.AddAccessRule($newRule2)
    #Write-Host "Added permission: $accessRights for $userOrGroupToAdd2"

    $subAcl.AddAccessRule($newRule3)
    #Write-Host "Added permission: $accessRights for $userOrGroupToAdd3"

    $subAcl.AddAccessRule($newRule4)
    #Write-Host "Added permission: $accessRights for $userOrGroupToAdd4"


    # Check if the ACL is inheriting
    if (-not $subAcl.AreAccessRulesProtected) {
        #Write-Host "The ACL is inheriting permissions. Stopping inheritance..."
        
        # Stop inheritance and protect the ACL
        $subAcl.SetAccessRuleProtection($true, $false)  # Protect the ACL and do not preserve inherited rules
    }

    <#
    # Find and remove all access rules for the specified user/group
    $rulesToRemove = $subAcl.Access | Where-Object { $_.IdentityReference -eq $userOrGroupToRemove }

    if ($rulesToRemove.Count -eq 0) {
        Write-Host "No permissions found for $userOrGroupToRemove."
    } else {
        foreach ($rule in $rulesToRemove) {
            # Remove the specific access rule for the user/group
            $subAcl.RemoveAccessRule($rule)
            Write-Host "Removed permission: $($rule.FileSystemRights) for $userOrGroupToRemove"
        }
    }
    #>

    # Apply the modified ACL back to the directory
    try {
        Set-Acl -Path $directoryPath -AclObject $subAcl -ErrorAction Stop
        Write-Host "Updated permissions for: $directoryPath"
    } catch {
        Write-Host "Failed to set ACL for: $directoryPath - $_"
    }

    <#
    # Apply the modified ACL to all subdirectories and files
    Get-ChildItem -Path $directoryPath -Recurse | ForEach-Object {
        try {
            Set-Acl -Path $_.FullName -AclObject $subAcl -ErrorAction Stop
            Write-Host "Updated permissions for subdir/file: $($_.FullName)"
            break # test only one path for now
        } catch {
            Write-Host "Failed to set ACL for subdir/file: $($_.FullName) - $_"
        }
    }
    #>
    # Display the final ACL
    #$subAcl = Get-Acl $directoryPath
    #$subAcl.Access | Format-Table -AutoSize
}

$rootDirPath = "D:\Data\Data"

Get-ChildItem -Path $rootDirPath -Recurse -Directory | Where-Object { $_.Name -like "*obsolete*" } | ForEach-Object {
    #Set-Permissions($_.FullName)
}