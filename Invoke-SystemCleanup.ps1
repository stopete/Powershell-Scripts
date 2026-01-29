# ------------------------------------------------------------
# Script Name : Advanced-SystemCleanup.ps1
# Purpose     : Disk Cleanup–style system maintenance
# Features    : Temp cleanup, Windows Update cache, browser cache,
#               component store cleanup, old user profiles, logging
# Recommended : Run as Administrator
# ------------------------------------------------------------

# ------------------------------------------------------------
# Configuration
# ------------------------------------------------------------

# Log file location
$LogPath = "C:\DoNotDelete\SystemCleanup.log"

# Number of days before user profiles are considered stale
$ProfileAgeDays = 2

# Enable or disable optional cleanup features
$EnableBrowserCleanup      = $true
$EnableProfileCleanup      = $false   # ⚠️ Disabled by default
$EnableComponentStoreClean = $true

# ------------------------------------------------------------
# Logging helper
# ------------------------------------------------------------

function Write-Log {
    param ([string]$Message)

    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    "$timestamp | $Message" | Tee-Object -FilePath $LogPath
}

Write-Log "===== System cleanup started ====="

# ------------------------------------------------------------
# Safe folder cleanup helper
# ------------------------------------------------------------

function Clear-Folder {
    param ([string]$Path)

    if (Test-Path $Path) {
        Write-Log "Cleaning: $Path"
        Get-ChildItem -Path $Path -Recurse -Force -ErrorAction SilentlyContinue |
            Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
    }
}

# ------------------------------------------------------------
# 1. TEMP file cleanup
# ------------------------------------------------------------

Write-Log "Cleaning TEMP folders"
Clear-Folder -Path $env:TEMP
Clear-Folder -Path "C:\Windows\Temp"

# ------------------------------------------------------------
# 2. Windows Update cache cleanup
# ------------------------------------------------------------

Write-Log "Cleaning Windows Update cache"
Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
Clear-Folder -Path "C:\Windows\SoftwareDistribution\Download"
Start-Service -Name wuauserv -ErrorAction SilentlyContinue

# ------------------------------------------------------------
# 3. Recycle Bin cleanup (all users)
# ------------------------------------------------------------

Write-Log "Emptying Recycle Bin"
Clear-RecycleBin -Force -ErrorAction SilentlyContinue

# ------------------------------------------------------------
# 4. Windows Error Reporting cleanup
# ------------------------------------------------------------

Clear-Folder -Path "C:\ProgramData\Microsoft\Windows\WER"

# ------------------------------------------------------------
# 5. Delivery Optimization cache
# ------------------------------------------------------------

Clear-Folder -Path "C:\Windows\ServiceProfiles\NetworkService\AppData\Local\Microsoft\Windows\DeliveryOptimization\Cache"

# ------------------------------------------------------------
# 6. Prefetch cleanup (safe – auto-regenerates)
# ------------------------------------------------------------

Clear-Folder -Path "C:\Windows\Prefetch"

# ------------------------------------------------------------
# 7. Browser cache cleanup (optional)
# ------------------------------------------------------------

if ($EnableBrowserCleanup) {
    Write-Log "Cleaning browser caches"

    # Microsoft Edge
    Clear-Folder -Path "$env:LOCALAPPDATA\Microsoft\Edge\User Data\Default\Cache"

    # Google Chrome
    Clear-Folder -Path "$env:LOCALAPPDATA\Google\Chrome\User Data\Default\Cache"
}

# ------------------------------------------------------------
# 8. Old user profile cleanup (OPTIONAL / RISKY)
# ------------------------------------------------------------

if ($EnableProfileCleanup) {
    Write-Log "Cleaning old user profiles older than $ProfileAgeDays days"

    Get-CimInstance Win32_UserProfile |
        Where-Object {
            -not $_.Special -and
            $_.LastUseTime -lt (Get-Date).AddDays(-$ProfileAgeDays)
        } |
        ForEach-Object {
            Write-Log "Removing user profile: $($_.LocalPath)"
            Remove-CimInstance $_
        }
}

# ------------------------------------------------------------
# 9. Component Store cleanup (WinSxS)
# ------------------------------------------------------------

if ($EnableComponentStoreClean) {
    Write-Log "Cleaning Windows Component Store (DISM)"
    Start-Process -FilePath "dism.exe" `
        -ArgumentList "/Online /Cleanup-Image /StartComponentCleanup /Quiet" `
        -Wait -WindowStyle Hidden
}

# ------------------------------------------------------------
# 10. Trigger built-in Disk Cleanup silently
# ------------------------------------------------------------

Write-Log "Running built-in Disk Cleanup"
Start-Process -FilePath "cleanmgr.exe" -ArgumentList "/verylowdisk" -WindowStyle Hidden

# ------------------------------------------------------------
# Completion
# ------------------------------------------------------------

Write-Log "===== System cleanup completed ====="
