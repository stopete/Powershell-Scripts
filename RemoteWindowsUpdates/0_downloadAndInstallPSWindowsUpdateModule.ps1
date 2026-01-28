# ------------------------------------------------------------
# PowerShell script to download and install the PSWindowsUpdate module
# IMPORTANT: Run this script as Administrator
# ------------------------------------------------------------

# Define the directory where the module will be downloaded
$TargetPath = "C:\DONotDelete"

# Define the PowerShell module name to install
$ModuleName = "PSWindowsUpdate"

# ------------------------------------------------------------
# Ensure the target directory exists
# ------------------------------------------------------------

# Check if the directory does NOT exist
if (-not (Test-Path $TargetPath)) {

    # Create the directory if missing
    New-Item -Path $TargetPath -ItemType Directory -Force

    # Notify the user that the directory was created
    Write-Host "Created directory: $TargetPath" -ForegroundColor Green
}

# ------------------------------------------------------------
# Check and temporarily adjust execution policy if required
# ------------------------------------------------------------

# Get the current PowerShell execution policy
$currentPolicy = Get-ExecutionPolicy

# If scripts are completely blocked, relax policy for current user only
if ($currentPolicy -eq "Restricted") {

    # Set execution policy to allow local scripts and signed remote scripts
    Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser -Force

    # Inform the user of the change
    Write-Host "Execution policy set to RemoteSigned for current user" -ForegroundColor Yellow
}

# ------------------------------------------------------------
# Download, import, and verify the PSWindowsUpdate module
# ------------------------------------------------------------

try {
    # Inform the user that the download is starting
    Write-Host "Downloading $ModuleName module to $TargetPath..." -ForegroundColor Cyan

    # Download the module from the PowerShell Gallery into the target directory
    Save-Module -Name $ModuleName -Path $TargetPath -Force -Repository PSGallery

    # Construct the full path to the downloaded module
    $ModulePath = Join-Path $TargetPath $ModuleName

    # Verify that the module directory exists
    if (Test-Path $ModulePath) {

        # Confirm successful download
        Write-Host "Module downloaded successfully to: $ModulePath" -ForegroundColor Green

        # Import the module from the custom path
        Import-Module $ModulePath -Force

        # Check whether the module was successfully imported
        $ImportedModule = Get-Module -Name $ModuleName

        if ($ImportedModule) {
            # Display module details for verification
            Write-Host "Module imported successfully!" -ForegroundColor Green
            Write-Host "Module Version: $($ImportedModule.Version)" -ForegroundColor Green
            Write-Host "Module Path: $($ImportedModule.ModuleBase)" -ForegroundColor Green
        }
    }
    else {
        # Throw an error if the module directory is missing
        throw "Module download failed - directory not found: $ModulePath"
    }
}
catch {
    # Display the error message and stop script execution
    Write-Error "Error downloading/installing module: $($_.Exception.Message)"
    exit 1
}

# ------------------------------------------------------------
# Display available commands from the installed module
# ------------------------------------------------------------

Write-Host "`nAvailable PSWindowsUpdate commands:" -ForegroundColor Cyan

# List all commands provided by the PSWindowsUpdate module
Get-Command -Module PSWindowsUpdate |
    Select-Object Name, CommandType |
    Format-Table -AutoSize

# ------------------------------------------------------------
# Completion message
# ------------------------------------------------------------

Write-Host "`nModule installation completed successfully!" -ForegroundColor Green
