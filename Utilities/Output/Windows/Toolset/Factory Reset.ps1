if($env:confirm -eq 'CONFIRM'){
    try {
        & systemreset -factoryreset
    }
    catch {
        Write-Host "Error Occured attempting to reset PC $($_.Exception)"
    }
}
else {
    throw "Invalid or no confirmation given please enter CONFIRM to confirm"
}
