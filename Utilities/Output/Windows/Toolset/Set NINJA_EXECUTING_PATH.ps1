try {
    [System.Environment]::SetEnvironmentVariable("NINJA_EXECUTING_PATH", "$($env:NINJA_EXECUTING_PATH)", [System.EnvironmentVariableTarget]::Machine)
}
catch {
    throw "Failed to set environment variable NINJA_EXECUTING_PATH=$($env:NINJA_EXECUTING_PATH)"
}