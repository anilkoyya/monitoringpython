# Parameters
$remoteComputer = "REMOTE-PC-NAME"  # Replace with target computer name
$installerPath = "\\Server\Share\Setup.exe"  # UNC path to the installer
$psexecPath = "C:\Tools\PsExec.exe"  # Local path to PsExec.exe
$username = "DOMAIN\AdminUser"  # Admin credentials
$password = "AdminPassword"  # Replace with secure password handling
$installArguments = "/quiet /norestart"  # Silent install arguments (modify as needed)

# Validate PsExec exists
if (-not (Test-Path $psexecPath)) {
    Write-Error "PsExec not found at $psexecPath. Please ensure PsExec is installed."
    exit 1
}

# Test network connectivity to remote computer
if (-not (Test-Connection -ComputerName $remoteComputer -Count 1 -Quiet)) {
    Write-Error "Unable to reach $remoteComputer. Check network connectivity."
    exit 1
}

# Command to execute PsExec
$command = "& '$psexecPath' \\$remoteComputer -u $username -p $password -h -s cmd /c '$installerPath $installArguments'"

# Execute PsExec command
try {
    Write-Host "Starting installation on $remoteComputer..."
    Invoke-Expression $command | Out-String | Write-Host
    Write-Host "Installation command sent successfully to $remoteComputer."
}
catch {
    Write-Error "Error executing installation on $remoteComputer : $_"
    exit 1
}

# Optional: Verify installation (example using a simple check)
$verifyCommand = "& '$psexecPath' \\$remoteComputer -u $username -p $password -h wmic product where 'name like ""%ApplicationName%""' get name,version"
try {
    $result = Invoke-Expression $verifyCommand
    if ($result -match "ApplicationName") {
        Write-Host "Application appears to be installed on $remoteComputer."
    } else {
        Write-Warning "Application not found on $remoteComputer. Installation may have failed."
    }
}
catch {
    Write-Error "Error verifying installation on $remoteComputer : $_"
}
