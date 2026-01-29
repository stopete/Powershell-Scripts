<#

    The script runs weekly via Task Scheduler to update Windows and Office 365.
    It creates/replaces a single log file (windowsupdates.log) with a timestamped
    header and footer. It ensures the PSWindowsUpdate module is available, registers
    Microsoft Update services, runs Office 365 updates if installed, checks for
    Windows/Microsoft updates, installs them automatically, and reboots if required.
    Errors and progress are logged for review.


#>


<#
.SYNOPSIS
    Automates installation of Chocolatey and updates essential applications with version checks, logging, silent mode, and error handling.

.DESCRIPTION
    This script ensures Chocolatey is installed, checks for pending reboot, then updates or installs a list of applications.
    It compares installed versions with Chocolatey versions and skips upgrades if the installed version is newer.
    Handles MSI error 1603 for VMware Horizon Client and logs detailed messages.
    Logs all actions (success, failure, skipped) to a file for auditing.
    Supports Silent Mode for automation (no console output).

.PARAMETER Apps
    List of Chocolatey package names to update or install.

.PARAMETER LogFile
    Path to the log file for recording update details.

.PARAMETER Silent
    Switch to suppress console output (useful for scheduled tasks).

.NOTES
    Author: [Your Name]
    Date:   [Date]
    Version: 7.0
#>

function Update-Applications {
    [CmdletBinding()]
    param (
        [string[]]$Apps = @(
            "googlechrome",
            "microsoft-teams",
            "adobereader",
            "7zip",
            "zoom",
            "vmware-horizon-client",
            "notepadplusplus"
        ),
        [string]$LogFile = "C:\Logs\AppUpdateLog.txt",
        [switch]$Silent
    )

    # Helper function for logging and optional console output
    function Write-Log {
        param (
            [string]$Message,
            [string]$Color = "White"
        )
        Add-Content -Path $LogFile -Value $Message
        if (-not $Silent) {
            Write-Host $Message -ForegroundColor $Color
        }
    }

    # Ensure log directory exists
    if (!(Test-Path (Split-Path $LogFile))) {
        New-Item -ItemType Directory -Path (Split-Path $LogFile) -Force | Out-Null
    }

    # Start logging
    Write-Log "`n===== Update Run: $(Get-Date) =====" "Cyan"
    Write-Log "Starting application update process..." "Cyan"

    # Check for pending reboot
    $pendingReboot = (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -ErrorAction SilentlyContinue) -or
                     (Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -ErrorAction SilentlyContinue)
    if ($pendingReboot) {
        Write-Log "WARNING: Pending reboot detected. Updates may fail. Please reboot before running this script." "Red"
    }

    try {
        # Check if Chocolatey is installed
        if (!(Get-Command choco -ErrorAction SilentlyContinue)) {
            Write-Log "Chocolatey not found. Installing Chocolatey..." "Yellow"
            Set-ExecutionPolicy Bypass -Scope Process -Force
            [System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor 3072

            $installScript = 'https://community.chocolatey.org/install.ps1'
            Invoke-Expression ((New-Object System.Net.WebClient).DownloadString($installScript))

            Write-Log "Chocolatey installed successfully." "Green"
        } else {
            Write-Log "Chocolatey is already installed." "Cyan"
        }

        # Update or install each application
        foreach ($app in $Apps) {
            Write-Log "Checking $app..." "Yellow"

            # Get Chocolatey package info
            $pkgInfo = choco info $app --limit-output | Out-String
            $rawChocoVersion = if ($pkgInfo -and ($pkgInfo -split '\|').Count -ge 2) { ($pkgInfo -split '\|')[1].Trim() } else { $null }
            $chocoVersion = if ($rawChocoVersion -match '^\d+(\.\d+){1,3}$') { $rawChocoVersion } else { $null }

            # Get installed version (if any)
            $installedInfo = choco list --local-only $app --limit-output | Out-String
            $rawInstalledVersion = if ($installedInfo -and ($installedInfo -split '\|').Count -ge 2) { ($installedInfo -split '\|')[1].Trim() } else { $null }
            $installedVersion = if ($rawInstalledVersion -match '^\d+(\.\d+){1,3}$') { $rawInstalledVersion } else { $null }

            # Decide action based on version info
            if (-not $installedVersion) {
                Write-Log "$app is NOT installed. Installing latest version..." "Yellow"
            } elseif ($installedVersion -and $chocoVersion) {
                try {
                    if ([version]$installedVersion -gt [version]$chocoVersion) {
                        Write-Log "$app skipped: Installed version ($installedVersion) is newer than Chocolatey ($chocoVersion)." "Yellow"
                        continue
                    } elseif ([version]$installedVersion -lt [version]$chocoVersion) {
                        Write-Log "$app is outdated (Installed: $installedVersion, Latest: $chocoVersion). Upgrading..." "Yellow"
                    } else {
                        Write-Log "$app is already up-to-date (Version: $installedVersion). Skipping..." "Green"
                        continue
                    }
                }
                catch {
                    Write-Log "Version comparison failed for $app. Proceeding with upgrade..." "Yellow"
                }
            } else {
                Write-Log "Version info missing or invalid for $app. Proceeding with upgrade..." "Yellow"
            }

            # Attempt upgrade or install
            $updateResult = choco upgrade $app -y --ignore-checksums 2>&1

            if ($LASTEXITCODE -eq 0) {
                Write-Log "$app updated/installed successfully." "Green"
            } else {
                # Special handling for MSI error 1603
                if ($updateResult -match "Exit code was '1603'") {
                    Write-Log "$app failed with MSI error (1603). Possible causes: pending reboot or same version installed. Check MSI log for details." "Red"
                }
                elseif ($updateResult -match "cannot replace a newer version") {
                    Write-Log "$app failed: Installed version is newer than Chocolatey package. Skipping future attempts." "Yellow"
                }
                else {
                    Write-Log "Failed to update/install $app. Details: $updateResult" "Red"
                }
            }
        }

        Write-Log "Update process completed!" "Green"
    }
    catch {
        Write-Log "An error occurred: $_" "Red"
    }
}




# --- Script: InstallUpdates.ps1 ---

# Log file path (single file, overwritten each run)
$logFile = "C:\DoNotDelete\windowsupdates.log"

# Start logging (overwrite each run)
if (Test-Path $logFile) { Remove-Item $logFile -Force }
Start-Transcript -Path $logFile -Force

try {
	
	Update-Applications
	
    $runDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    Write-Host "=============================================" -ForegroundColor Yellow
    Write-Host "   Windows Update Run - $runDate" -ForegroundColor Yellow
    Write-Host "=============================================" -ForegroundColor Yellow

    # Force TLS 1.2 (required for secure downloads)
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    # Ensure PSWindowsUpdate module is available

    <#
    if (-not (Get-Module PSWindowsUpdate -ListAvailable)) {
        throw "PSWindowsUpdate module not installed. Please install it manually using:
               Install-Module -Name PSWindowsUpdate -Force"
    }
    #>

    Import-Module PowerShellGet

    Install-Module -Name PSWindowsUpdate -Force

    Import-Module PSWindowsUpdate -Force


    # Register Microsoft Update service if missing
    $ServiceID = "7971f918-a847-4430-9279-4a52d1efe18d"
    if (-not (Get-WUServiceManager | Where-Object ServiceID -eq $ServiceID)) {
        Add-WUServiceManager -ServiceID $ServiceID -Confirm:$false
    }

    # Update Office 365 if available
    $officeFile = "C:\Program Files\Common Files\microsoft shared\ClickToRun\OfficeC2RClient.exe"
    if (Test-Path $officeFile) {
        Write-Host "Running Office365 updates..."
        & $officeFile /update user updatepromptuser=False forceappshutdown=true displaylevel=false
    }

    # Windows Updates
    Write-Host "Checking for Windows Updates..."
    Get-WindowsUpdate -MicrosoftUpdate -IgnoreUserInput

    Write-Host "Installing Windows Updates..."
    Install-WindowsUpdate -MicrosoftUpdate -AcceptAll -AutoReboot -IgnoreUserInput -Confirm:$false

    Write-Host "==== Script completed successfully at $(Get-Date) ====" -ForegroundColor Green

} catch {
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}

$endDate = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
Write-Host "=============================================" -ForegroundColor Yellow
Write-Host "   End of Windows Update Run - $endDate" -ForegroundColor Yellow
Write-Host "=============================================" -ForegroundColor Yellow

Stop-Transcript
