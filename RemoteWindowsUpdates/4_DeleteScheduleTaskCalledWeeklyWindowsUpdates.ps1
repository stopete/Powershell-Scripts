# ------------------------------------------------------------
# Purpose: Delete the scheduled task "WeeklyWindowsUpdates"
# ------------------------------------------------------------

# Name of the scheduled task to delete
$TaskName = "WeeklyWindowsUpdates"

# Attempt to retrieve the scheduled task
# SilentlyContinue prevents errors if the task does not exist
$task = Get-ScheduledTask -TaskName $TaskName -ErrorAction SilentlyContinue

# Check if the task exists
if ($null -eq $task) {

    # Inform the user that the task was not found
    Write-Host "Scheduled task '$TaskName' does not exist. Nothing to delete." -ForegroundColor Yellow

    # Exit gracefully
    exit 0
}

# ------------------------------------------------------------
# Stop the task if it is currently running (optional safety step)
# ------------------------------------------------------------

# Check if the task is running
$taskState = (Get-ScheduledTaskInfo -TaskName $TaskName).State
if ($taskState -eq 'Running') {

    # Stop the running task before deletion
    Stop-ScheduledTask -TaskName $TaskName

    Write-Host "Stopped running task '$TaskName'." -ForegroundColor Yellow
}

# ------------------------------------------------------------
# Delete the scheduled task
# ------------------------------------------------------------

# Remove the scheduled task without confirmation
Unregister-ScheduledTask -TaskName $TaskName -Confirm:$false

# Confirm deletion
Write-Host "Scheduled task '$TaskName' has been successfully deleted." -ForegroundColor Green
