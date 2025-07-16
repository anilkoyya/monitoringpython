# PowerShell script to scan App-V 5 package repository and export results to Excel

# Parameters
param (
    [Parameter(Mandatory=$true)]
    [string]$RepositoryPath, # Path to the repository containing App-V packages
    [Parameter(Mandatory=$true)]
    [string]$OutputExcelPath # Path for the output Excel file
)

# Function to check if a file or directory exists
function Test-PathExists {
    param (
        [string]$Path
    )
    if (-not (Test-Path -Path $Path)) {
        Write-Error "Path not found: $Path"
        exit 1
    }
}

# Function to extract XML from App-V package
function Get-AppVManifest {
    param (
        [string]$PackageDir
    )
    $manifestPath = Join-Path -Path $PackageDir -ChildPath "AppxManifest.xml"
    
    if (-not (Test-Path -Path $manifestPath)) {
        return $null
    }
    
    try {
        [xml]$manifest = Get-Content -Path $manifestPath
        return $manifest
    }
    catch {
        Write-Warning "Failed to parse AppxManifest.xml in $PackageDir : $_"
        return $null
    }
}

# Function to check for custom scripts in the manifest
function Get-CustomScripts {
    param (
        [xml]$Manifest,
        [string]$PackageName
    )
    $results = @()
    
    if ($null -eq $Manifest) {
        return $results
    }
    
    # Check for UserScripts or MachineScripts
    $scriptNodes = $Manifest.Package.Extensions.Extension | Where-Object { 
        $_.Category -eq "AppV.UserScripts" -or $_.Category -eq "AppV.MachineScripts"
    }
    
    if ($null -eq $scriptNodes) {
        $results += [PSCustomObject]@{
            PackageName  = $PackageName
            ScriptType   = "None"
            ScriptPath   = ""
            Arguments    = ""
            Wait         = ""
            Timeout      = ""
        }
        return $results
    }
    
    foreach ($extension in $scriptNodes) {
        $scriptType = $extension.Category
        $scripts = $extension.UserScripts | Get-Member -MemberType Property | Where-Object { $_.Name -like "*Script" }
        
        foreach ($script in $scripts) {
            $scriptName = $script.Name
            $scriptDetails = $extension.UserScripts.$scriptName
            
            if ($scriptDetails) {
                $results += [PSCustomObject]@{
                    PackageName  = $PackageName
                    ScriptType   = $scriptName
                    ScriptPath   = $scriptDetails.Path
                    Arguments    = $scriptDetails.Arguments
                    Wait         = $scriptDetails.Wait
                    Timeout      = $scriptDetails.Timeout
                }
            }
        }
    }
    
    if ($results.Count -eq 0) {
        $results += [PSCustomObject]@{
            PackageName  = $PackageName
            ScriptType   = "None"
            ScriptPath   = ""
            Arguments    = ""
            Wait         = ""
            Timeout      = ""
        }
    }
    
    return $results
}

# Main script logic
try {
    # Validate repository path
    Test-PathExists -Path $RepositoryPath
    
    # Ensure ImportExcel module is available
    if (-not (Get-Module -ListAvailable -Name ImportExcel)) {
        Write-Error "ImportExcel module not found. Please install it using: Install-Module -Name ImportExcel"
        exit 1
    }
    
    Import-Module -Name ImportExcel -Force
    
    # Initialize results array
    $allResults = @()
    
    # Get all items in the repository
    $items = Get-ChildItem -Path $RepositoryPath -Recurse
    
    Write-Host "Scanning repository: $RepositoryPath" -ForegroundColor Cyan
    
    foreach ($item in $items) {
        $packageName = $item.Name
        $packagePath = $item.FullName
        
        if ($item.PSIsContainer) {
            # Process as extracted package folder
            $manifest = Get-AppVManifest -PackageDir $packagePath
            $results = Get-CustomScripts -Manifest $manifest -PackageName $packageName
            $allResults += $results
        }
        elseif ($item.Extension -eq ".appv") {
            # For .appv files, warn about extraction requirement
            Write-Warning "Found .appv file: $packageName. Please extract the package to scan its contents."
            $allResults += [PSCustomObject]@{
                PackageName  = $packageName
                ScriptType   = "Not Scanned"
                ScriptPath   = "Requires extraction"
                Arguments    = ""
                Wait         = ""
                Timeout      = ""
            }
        }
    }
    
    # Export results to Excel
    if ($allResults.Count -eq 0) {
        Write-Host "No App-V packages or scripts found in the repository." -ForegroundColor Yellow
    }
    else {
        Write-Host "Exporting results to $OutputExcelPath" -ForegroundColor Cyan
        $allResults | Export-Excel -Path $OutputExcelPath -AutoSize -AutoFilter -FreezeTopRow -BoldTopRow -WorksheetName "AppV_Script_Report"
        Write-Host "Export completed successfully." -ForegroundColor Green
    }
}
catch {
    Write-Error "An error occurred: $_"
    exit 1
}
