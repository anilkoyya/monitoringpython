# PowerShell script to scan App-V 5 package for custom scripts in Package Descriptor XML

# Parameters
param (
    [Parameter(Mandatory=$true)]
    [string]$PackagePath # Path to the extracted App-V package or .appv file
)

# Function to check if a file exists
function Test-FileExists {
    param (
        [string]$Path
    )
    if (-not (Test-Path -Path $Path)) {
        Write-Error "File or directory not found: $Path"
        exit 1
    }
}

# Function to extract XML from App-V package
function Get-AppVManifest {
    param (
        [string]$PackageDir
    )
    $manifestPath = Join-Path -Path $PackageDir -ChildPath "AppxManifest.xml"
    
    Test-FileExists -Path $manifestPath
    
    try {
        [xml]$manifest = Get-Content -Path $manifestPath
        return $manifest
    }
    catch {
        Write-Error "Failed to parse AppxManifest.xml: $_"
        exit 1
    }
}

# Function to check for custom scripts in the manifest
function Find-CustomScripts {
    param (
        [xml]$Manifest
    )
    
    Write-Host "Scanning for custom scripts in Package Descriptor XML..." -ForegroundColor Cyan
    
    # Check for UserScripts or MachineScripts
    $scriptNodes = $Manifest.Package.Extensions.Extension | Where-Object { 
        $_.Category -eq "AppV.UserScripts" -or $_.Category -eq "AppV.MachineScripts"
    }
    
    if ($null -eq $scriptNodes) {
        Write-Host "No custom scripts found in the package descriptor." -ForegroundColor Yellow
        return
    }
    
    # Iterate through script nodes
    $scriptFound = $false
    foreach ($extension in $scriptNodes) {
        $scriptType = $extension.Category
        Write-Host "`nFound scripts in category: $scriptType" -ForegroundColor Green
        
        # Check for various script types
        $scripts = $extension.UserScripts | Get-Member -MemberType Property | Where-Object { $_.Name -like "*Script" }
        foreach ($script in $scripts) {
            $scriptName = $script.Name
            $scriptDetails = $extension.UserScripts.$scriptName
            
            if ($scriptDetails) {
                $scriptFound = $true
                Write-Host "Script Type: $scriptName" -ForegroundColor White
                Write-Host "  Path: $($scriptDetails.Path)"
                Write-Host "  Arguments: $($scriptDetails.Arguments)"
                Write-Host "  Wait: $($scriptDetails.Wait)"
                Write-Host "  Timeout: $($scriptDetails.Timeout)"
            }
        }
    }
    
    if (-not $scriptFound) {
        Write-Host "No specific script details found under UserScripts or MachineScripts." -ForegroundColor Yellow
    }
}

# Main script logic
try {
    # Validate package path
    Test-FileExists -Path $PackagePath
    
    # Check if the path is a directory or .appv file
    if ((Get-Item $PackagePath).PSIsContainer) {
        # Directory containing extracted App-V package
        $manifest = Get-AppVManifest -PackageDir $PackagePath
    }
    else {
        # For .appv file, you may need to extract it first (requires App-V infrastructure or tools)
        Write-Warning ".appv file detected. Please extract the package to a folder and provide the folder path."
        Write-Host "Alternatively, ensure the App-V client is installed and use 'Mount-AppvClientPackage' to access contents."
        exit 1
    }
    
    # Scan for custom scripts
    Find-CustomScripts -Manifest $manifest
    
    Write-Host "`nScan completed successfully." -ForegroundColor Green
}
catch {
    Write-Error "An error occurred: $_"
    exit 1
}
