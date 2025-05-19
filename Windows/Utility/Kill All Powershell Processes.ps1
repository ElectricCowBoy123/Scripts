$procs = Get-Process | Where-Object {$_.Name -like "*Powershell*"}
if($procs){
	foreach ($proc in $procs) {
		try {
			$proc.Kill()
			Write-Host "Terminated Process: $($proc.Name) (ID: $($proc.Id))"
		} 
		catch {
			Write-Host "Failed to Terminate Process: $($proc.Name) (ID: $($proc.Id)) Error: $($_.Exception)"
		}
	}
}
else {
    Write-Host "Didn't find any Processes!"
}