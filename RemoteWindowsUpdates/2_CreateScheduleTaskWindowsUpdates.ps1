# ------------------------------------------------------------
# Purpose: Create or update a Scheduled Task that runs
#          InstallUpdates.ps1 weekly as SYSTEM
# ------------------------------------------------------------

# ------------------------------------------------------------
# Parameters
# ------------------------------------------------------------

# Name of the scheduled task
# NOTE: Leading backslash places the task in the root Task Scheduler folder
$TaskName = '\WeeklyWindowsUpdates'

# Full path to the PowerShell script that will be executed by the task
$Script   = 'C:\DoNotDelete\InstallUpdates.ps1'

# ------------------------------------------------------------
# Ensure the script path exists (safety check)
# ------------------------------------------------------------

# Check if the target script file exists
if (-not (Test-Path $Script)) {

    # Create the parent directory if it does not exist
    New-Item -ItemType Directory -Path (Split-Path $Script -Parent) -Force | Out-Null

    # Create a placeholder InstallUpdates.ps1 script
    # This prevents the scheduled task from failing due to a missing file
    @'
# InstallUpdates.ps1
# TODO: Add your update installation logic here.
'@ | Out-File -FilePath $Script -Encoding UTF8 -Force
}

# ------------------------------------------------------------
# Define the scheduled task action
# ------------------------------------------------------------

# Executable used by the scheduled task
$Action = 'PowerShell.exe'

# Arguments passed to PowerShell.exe
# Quotes ensure paths with spaces are handled correctly
$Args   = ('"{0}"' -f $Script)

# ------------------------------------------------------------
# Create or update the scheduled task
# ------------------------------------------------------------

# Create (or overwrite) the scheduled task with the following settings:
# - Runs weekly
# - Executes every Tuesday
# - Starts at 22:00 (10:00 PM)
# - Runs as the SYSTEM account
# - Runs with highest privileges
# - /F forces overwrite if the task already exists
schtasks.exe /Create `
    /TN $TaskName `
    /TR ('"{0}" {1}' -f $Action, $Args) `
    /SC WEEKLY `
    /D TUE `
    /ST 22:00 `
    /RU "SYSTEM" `
    /RL HIGHEST `
    /F

# ------------------------------------------------------------
# Display task details for verification (optional)
# ------------------------------------------------------------

# Output full details of the scheduled task
schtasks.exe /Query /TN $TaskName /V /FO LIST
