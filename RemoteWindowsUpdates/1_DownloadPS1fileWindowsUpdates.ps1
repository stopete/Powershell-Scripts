# ------------------------------------------------------------
# Purpose: Download a ZIP file, extract its contents, copy
#          InstallUpdates.ps1 to C:\DoNotDelete, and clean up
# ------------------------------------------------------------

# Define the destination folder where files will be stored
$destinationFolder = "C:\DoNotDelete"

# Check if the destination folder exists
if (-not (Test-Path $destinationFolder)) {

    # Create the destination folder if it does not exist
    New-Item -Path $destinationFolder -ItemType Directory -Force
}

# ------------------------------------------------------------
# Download the ZIP file from the specified URL
# ------------------------------------------------------------

# URL of the ZIP file containing InstallUpdates.ps1
$zipUrl = "http://ServerName:8624/endpoints/Public-Files/content/InstallUpdates.zip"

# Local path where the ZIP file will be saved
$zipPath = Join-Path $destinationFolder "InstallUpdates.zip"

# Download the ZIP file to the destination folder
Invoke-WebRequest -Uri $zipUrl -OutFile $zipPath

# ------------------------------------------------------------
# Extract the ZIP file to a temporary directory
# ------------------------------------------------------------

# Temporary folder used for extracting ZIP contents
$extractPath = Join-Path $destinationFolder "temp_extract"

# Extract the ZIP file contents, overwriting existing files if necessary
Expand-Archive -Path $zipPath -DestinationPath $extractPath -Force

# ------------------------------------------------------------
# Locate and copy InstallUpdates.ps1 to the destination folder
# ------------------------------------------------------------

# Search recursively for InstallUpdates.ps1 within the extracted files
$sourceFile = Get-ChildItem `
    -Path $extractPath `
    -Filter "InstallUpdates.ps1" `
    -Recurse |
    Select-Object -First 1

# If the script is found, copy it to C:\DoNotDelete
if ($sourceFile) {

    # Copy the file, overwriting any existing version
    Copy-Item -Path $sourceFile.FullName -Destination $destinationFolder -Force

    # Confirm successful copy
    Write-Host "InstallUpdates.ps1 copied successfully to $destinationFolder"
}
else {
    # Notify the user if the file was not found
    Write-Host "InstallUpdates.ps1 not found in the extracted files"
}

# ------------------------------------------------------------
# Clean up temporary files
# ------------------------------------------------------------

# Remove the temporary extraction folder and all its contents
Remove-Item -Path $extractPath -Recurse -Force

# Optional: Remove the downloaded ZIP file after extraction
 Remove-Item -Path $zipPath -Force

# ------------------------------------------------------------
# Completion message
# ------------------------------------------------------------

Write-Host "Process completed"
