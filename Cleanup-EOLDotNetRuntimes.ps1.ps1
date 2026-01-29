# ================================
# PURPOSE:
# When Unisntalling .NET runtimes the directories don't 
# get remove/delete so this script will automate this process
# Remove End-of-Life (EOL) .NET runtimes (configurable)
# from BOTH x64 and x86 dotnet directories
# Provides messages for each version: found & deleted, or not found
# ================================

# Stop IIS services to prevent file locks
Write-Host "Stopping IIS to avoid file locks..." -ForegroundColor Yellow
Stop-Service w3svc -Force -ErrorAction SilentlyContinue
Stop-Service iisadmin -Force -ErrorAction SilentlyContinue

# Versions to remove — change these as needed
$eolVersions = @("2.1.30", "5.0.17")

# Both dotnet root directories
$dotnetRoots = @(
    "C:\Program Files\dotnet",
    "C:\Program Files (x86)\dotnet"
)

# Track if we deleted anything
$deletedAnything = $false

foreach ($root in $dotnetRoots) {

    if (-not (Test-Path $root)) {
        Write-Host "Skipping (not found): $root" -ForegroundColor DarkGray
        continue
    }

    Write-Host "`nScanning $root ..." -ForegroundColor Cyan

    $sharedPath = Join-Path $root "shared"

    # Enumerate each runtime family
    Get-ChildItem $sharedPath -Directory -ErrorAction SilentlyContinue | ForEach-Object {

        $runtimeFamily = $_.FullName

        foreach ($version in $eolVersions) {

        write-Host ""

            # Inform that we are scanning this version in this family
            Write-Host "Scanning for version $version in $runtimeFamily ..." -ForegroundColor DarkCyan
            
            $versionPath = Join-Path $runtimeFamily $version

            if (Test-Path $versionPath) {
                $deletedAnything = $true
                Write-Host "Deleted EOL runtime: $versionPath" -ForegroundColor Red

                # Take ownership and grant full control before deletion
                Takeown /f $versionPath /r /d y | Out-Null
                Icacls $versionPath /grant Administrators:F /t | Out-Null

                Remove-Item $versionPath -Recurse -Force
            }
            else {
                Write-Host "Not found: $versionPath" -ForegroundColor Yellow
            }
        }
    }
}

# Final summary
if ($deletedAnything) {
    Write-Host "`nFinished cleanup: Some EOL runtime folders were found and deleted." -ForegroundColor Green
} else {
    Write-Host "`nNo EOL runtime folders were found to delete." -ForegroundColor Green
}

# ================================
# Verification Section
# ================================

Write-Host "`nCurrent installed .NET runtimes after cleanup:" -ForegroundColor Magenta

Write-Host "`n--- x64 runtimes ---" -ForegroundColor Cyan
dotnet --list-runtimes

if (Test-Path "C:\Program Files (x86)\dotnet\dotnet.exe") {
    Write-Host "`n--- x86 runtimes ---" -ForegroundColor Cyan
    & "C:\Program Files (x86)\dotnet\dotnet.exe" --list-runtimes
} else {
    Write-Host "`nNo x86 dotnet runtime present." -ForegroundColor Green
}


