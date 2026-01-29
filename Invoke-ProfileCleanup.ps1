<#
.SYNOPSIS
Automatically deletes unused, non-special local user profiles.

.DESCRIPTION
This script scans the system's local user profiles using the Win32_UserProfile
CIM class and identifies profiles that:
    - Are not currently loaded (`Loaded -eq $false`)
    - Are not special profiles (`Special -eq $false`)
    - Have a valid LocalPath (not null)

These profiles are typically stale local user profiles created by accounts that
no longer log into the system. Such profiles can consume disk space unnecessarily.

The script lists the profiles it found and then deletes them automatically
(no confirmation prompt). Output is sent to the console.

.NOTES
Requires:
    - Administrator privileges
    - Windows OS with Win32_UserProfile CIM class available

Deletion is permanent — verify logic before deploying widely.

.EXAMPLE
PS> .\Remove-StaleUserProfiles.ps1
Finds and deletes all stale, non-special profiles that are not currently loaded.

#>

# ------------------------------------------------------------
# Retrieve user profiles that are safe to delete
# ------------------------------------------------------------
# We filter out:
#   - Loaded profiles     → cannot delete profiles that are currently in use
#   - Special profiles    → system-managed profiles (Default, Public, etc.)
#   - Null LocalPath      → malformed or invalid profile entries
$ProfilesToDelete = Get-CimInstance -ClassName Win32_UserProfile | Where-Object {
    ($_.Loaded -eq $false) -and
    ($_.Special -eq $false) -and
    ($_.LocalPath -ne $null)
}

# ------------------------------------------------------------
# No profiles found
# ------------------------------------------------------------
if ($ProfilesToDelete.Count -eq 0) {
    Write-Host "No user profiles found to delete."
}
else {
    # ------------------------------------------------------------
    # Display the profiles that will be deleted
    # ------------------------------------------------------------
    Write-Host "Deleting the following profiles:`n"

    $ProfilesToDelete |
        Select-Object -Property LocalPath, Loaded, Special |
        Format-Table -AutoSize

    # ------------------------------------------------------------
    # Delete profiles (no prompt)
    # ------------------------------------------------------------
    # Remove-CimInstance permanently deletes the user profile directory
    # and registry entries associated with that profile.
    $ProfilesToDelete | Remove-CimInstance -ErrorAction SilentlyContinue

    Write-Host "`nCompleted deleting user profiles!"
}

Write-Host ""