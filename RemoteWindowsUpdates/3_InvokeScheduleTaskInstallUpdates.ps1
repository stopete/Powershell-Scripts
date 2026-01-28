# ------------------------------------------------------------
# Purpose: Manually trigger an existing scheduled task
# ------------------------------------------------------------

# Name of the scheduled task to trigger
$TaskName = "WeeklyWindowsUpdates"

# Attempt to retrieve the scheduled task
# -ErrorAction SilentlyContinue prevents errors if the task does not exist
$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

# Check if the task was found
if ($null -eq $task) {

    # Output an error message if the task does not exist
    Write-Error "Scheduled task '$TaskName' was not found."

    # Exit the script with a non-zero exit code
    exit 1
}

# Start (trigger) the scheduled task immediately
Start-ScheduledTask -TaskName $TaskName

# Confirm that the task was successfully triggered
Write-Host "Scheduled task '$TaskName' has been triggered."


