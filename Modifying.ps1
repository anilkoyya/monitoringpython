# Parameters
$remoteComputer = "REMOTE-PC-NAME"  # Replace with target computer name
$scriptPath = "\\Server\Share\control.cmd"  # UNC path to control.cmd
$scriptDir = [System.IO.Path]::GetDirectoryName($scriptPath)  # Extract directory
$scriptFile = [System.IO.Path]::GetFileName($scriptPath)  # Extract file name
$psexecPath = "C:\Tools\PsExec.exe"  # Local path to PsExec.exe
$username = "DOMAIN\AdminUser"  # Admin credentials
$password = "AdminPassword"  # Replace with secure password handling
$logFile = "C:\Logs\Install_Log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt"  # Log file path

# Create log directory if it doesn't exist
$logDir = Split-Path $logFile -Parent
if (-not (Test-Path $logDir)) {
    New-Item -ItemType Directory -Path $logDir -Force | Out-Null
}

# Function to log messages
function Write-Log {
    param ([string]$Message)
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp - $Message" | Out-File -FilePath $logFile -Append
    Write-Host $Message
}

# Validate PsExec exists
if (-not (Test-Path $psexecPath)) {
    Write-Log "ERROR: PsExec not found at $psexecPath. Please ensure PsExec is installed."
    exit 1
}

# Test network connectivity to remote computer
if (-not (Test-Connection -ComputerName $remoteComputer -Count 1 -Quiet)) {
    Write-Log "ERROR: Unable to reach $remoteComputer. Check network connectivity or DNS resolution."
    exit 1
}

# Validate script path accessibility from local machine
if (-not (Test-Path $scriptPath)) {
    Write-Log "ERROR: Script path $scriptPath is not accessible from local machine."
    exit 1
}

# Check if PsExec can connect to remote computer (test basic connectivity)
$testPsExecCommand = "& `"$psexecPath`" \\$remoteComputer -u `"$username`" -p `"$password`" -h cmd /c echo ."
try {
    Write-Log "Testing PsExec connectivity to $remoteComputer..."
    $testOutput = Invoke-Expression $testPsExecCommand 2>&1 | Out-String
    Write-Log $testOutput
    if ($testOutput -match "handle is invalid" -or $testOutput -match "Access is denied") {
        Write-Log "ERROR: PsExec failed to connect to $remoteComputer. Check credentials, firewall, or services."
        exit 1
    }
}
catch {
    Write-Log "ERROR: PsExec connectivity test failed on $remoteComputer : $_"
    exit 1
}

# Validate script directory accessibility on remote machine
$testDirCommand = "& `"$psexecPath`" \\$remoteComputer -u `"$username`" -p `"$password`" -h cmd /c dir `"$scriptDir`""
try {
    Write-Log "Validating access to $scriptDir on $remoteComputer..."
    $dirOutput = Invoke-Expression $testDirCommand 2>&1 | Out-String
    Write-Log $dirOutput
    if ($dirOutput -match " dir cmd" -or $dirOutput -match "Access is denied") {
        Write-Log "ERROR: Cannot access $scriptDir on $remoteComputer. Check permissions or path."
        exit 1
    }
}
catch {
    Write-Log "ERROR: Failed to validate $scriptDir on $remoteComputer : $_"
    exit 1
}

# Execute control.cmd from the script's directory
$command = "& `"$psexecPath`" \\$remoteComputer -u `"$username`" -p `"$password`" -h -s cmd /c \`"cd /d \`"$scriptDir\`" && call $scriptFile\`""
try {
    Write-Log "Starting execution of $scriptFile on $remoteComputer from $scriptDir..."
    $scriptOutput = Invoke-Expression $command 2>&1 | Out-String
    Write-Log $scriptOutput
    if ($scriptOutput -match "exited with error code 0") {
        Write-Log "Script execution command sent successfully to $remoteComputer."
    } else {
        Write-Log "ERROR: Script execution may have failed. PsExec output: $scriptOutput"
        exit 1
    }
}
catch {
    Write-Log "ERROR: Failed to execute $scriptFile on $remoteComputer : $_"
    exit 1
}
