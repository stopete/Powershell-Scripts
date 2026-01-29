function Update-Modules {
    [CmdletBinding(SupportsShouldProcess = $true)]
    param (
        [switch]$AllowPrerelease,
        [string]$Name = '*',
        [string[]]$Exclude,
        [ValidateSet('AllUsers', 'CurrentUser')]
        [string]$Scope = 'AllUsers'
    )

    # ------------------------------------------------------------
    # Capture whether the caller used common parameters
    # (Verbose/WhatIf are *already available* via CmdletBinding)
    # ------------------------------------------------------------
    $UseVerbose = $PSBoundParameters.ContainsKey('Verbose')
    $UseWhatIf  = $PSBoundParameters.ContainsKey('WhatIf')

    # ------------------------------------------------------------
    # Admin check for AllUsers scope on Windows
    # ------------------------------------------------------------
    if ($IsWindows -and $Scope -eq 'AllUsers') {
        $isAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).
            IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator")

        if (-not $isAdmin) {
            Write-Warning ("Function {0} needs admin privileges for Scope=AllUsers. Exiting." -f $MyInvocation.MyCommand)
            return
        }
    }

    # ------------------------------------------------------------
    # Non-Windows: force CurrentUser scope
    # ------------------------------------------------------------
    if (-not $IsWindows) {
        $Scope = 'CurrentUser'
    }

    # ------------------------------------------------------------
    # Retrieve installed modules and apply optional exclusion
    # ------------------------------------------------------------
    Write-Host "Retrieving all installed modules ..." -ForegroundColor Green

    $CurrentModules = foreach ($InstalledModule in Get-InstalledModule -Name $Name -ErrorAction SilentlyContinue) {
        if ($Exclude) {
            # Skip any module whose name matches exclude patterns
            if (-not ($InstalledModule.Name | Select-String $Exclude)) {
                [PSCustomObject]@{ Name = $InstalledModule.Name; Version = $InstalledModule.Version }
            }
        }
        else {
            [PSCustomObject]@{ Name = $InstalledModule.Name; Version = $InstalledModule.Version }
        }
    }

    if (-not $CurrentModules) {
        Write-Host "No modules found." -ForegroundColor Gray
        return
    }

    $ModulesCount = $CurrentModules.Name.Count
    $DigitsLength = $ModulesCount.ToString().Length
    Write-Host ("{0} modules found." -f $ModulesCount) -ForegroundColor Gray

    ''
    if ($AllowPrerelease) {
        Write-Host "Updating installed modules to the latest PreRelease version ..." -ForegroundColor Green
    }
    else {
        Write-Host "Updating installed modules to the latest Production version ..." -ForegroundColor Green
    }

    # ------------------------------------------------------------
    # Query online versions from PSGallery (chunked to avoid limits)
    # ------------------------------------------------------------
    $onlineversions = @()

    if ($CurrentModules.Count -eq 1) {
        Write-Host ("Checking online versions for installed module {0}" -f $CurrentModules.Name) -ForegroundColor Green
        $onlineversions += Find-Module -Name $CurrentModules.Name -ErrorAction SilentlyContinue
    }
    else {
        $startnumber = 0
        $endnumber   = 62

        while ($startnumber -lt $CurrentModules.Count) {
            $sliceEnd = [Math]::Min($endnumber, $CurrentModules.Count - 1)

            Write-Host ("Checking online versions for installed modules [{0}..{1}/{2}]" -f $startnumber, $sliceEnd, $CurrentModules.Count) -ForegroundColor Green
            $onlineversions += Find-Module -Name $CurrentModules.Name[$startnumber..$sliceEnd] -ErrorAction SilentlyContinue

            $startnumber += 63
            $endnumber   += 63
        }
    }

    # ------------------------------------------------------------
    # Update installed modules when newer versions exist
    # ------------------------------------------------------------
    $i = 0
    foreach ($Module in $CurrentModules | Sort-Object Name) {
        $i++
        $Counter = ("[{0,$DigitsLength}/{1,$DigitsLength}]" -f $i, $ModulesCount)
        $CounterLength = $Counter.Length

        Write-Host ("{0} Checking for updated version of module {1} ..." -f $Counter, $Module.Name) -ForegroundColor Green

        try {
            $latest = $onlineversions | Where-Object Name -EQ $Module.Name | Select-Object -First 1

            if ($latest -and ([version]$Module.Version -lt [version]$latest.Version)) {

                # Supports -WhatIf automatically via SupportsShouldProcess,
                # but we also pass WhatIf/Verbose explicitly to nested cmdlets.
                if ($PSCmdlet.ShouldProcess($Module.Name, "Update module to $($latest.Version)")) {
                    Update-Module -Name $Module.Name `
                        -AllowPrerelease:$AllowPrerelease `
                        -AcceptLicense `
                        -Scope $Scope `
                        -Force:$true `
                        -ErrorAction Stop `
                        -WhatIf:$UseWhatIf `
                        -Verbose:$UseVerbose
                }
            }
        }
        catch {
            Write-Host ("{0,$CounterLength} Error updating module {1}! {2}" -f ' ', $Module.Name, $_.Exception.Message) -ForegroundColor Red
        }

        # ------------------------------------------------------------
        # Remove older versions (keep the most recent)
        # ------------------------------------------------------------
        $AllVersions = Get-InstalledModule -Name $Module.Name -AllVersions -ErrorAction SilentlyContinue |
            Sort-Object PublishedDate -Descending

        if ($AllVersions -and $AllVersions.Count -gt 1) {
            $MostRecentVersion = $AllVersions[0].Version

            foreach ($Version in $AllVersions) {
                if ($Version.Version -ne $MostRecentVersion) {
                    try {
                        Write-Host ("{0,$CounterLength} Uninstalling previous version {1} of module {2} ..." -f ' ', $Version.Version, $Module.Name) -ForegroundColor Gray

                        if ($PSCmdlet.ShouldProcess($Module.Name, "Uninstall module version $($Version.Version)")) {
                            Uninstall-Module -Name $Module.Name `
                                -RequiredVersion $Version.Version `
                                -Force:$true `
                                -ErrorAction Stop `
                                -AllowPrerelease `
                                -WhatIf:$UseWhatIf `
                                -Verbose:$UseVerbose
                        }
                    }
                    catch {
                        Write-Warning ("{0,$CounterLength} Error uninstalling previous version {1} of module {2}! {3}" -f ' ', $Version.Version, $Module.Name, $_.Exception.Message)
                    }
                }
            }
        }
    }

    # ------------------------------------------------------------
    # Summary: show what changed
    # ------------------------------------------------------------
    $NewModules = Get-InstalledModule -Name $Name -ErrorAction SilentlyContinue |
        Select-Object Name, Version | Sort-Object Name

    if ($NewModules) {
        ''
        Write-Host "List of updated modules:" -ForegroundColor Green

        $NoUpdatesFound = $true
        foreach ($Module in $NewModules) {
            $Old = $CurrentModules | Where-Object Name -EQ $Module.Name | Select-Object -First 1
            if ($Old -and ($Old.Version -ne $Module.Version)) {
                $NoUpdatesFound = $false
                Write-Host ("- Updated module {0} from version {1} to {2}" -f $Module.Name, $Old.Version, $Module.Version) -ForegroundColor Green
            }
        }

        if ($NoUpdatesFound) {
            Write-Host "No modules were updated." -ForegroundColor Gray
        }
    }
}

# Run it (supports -Verbose and -WhatIf automatically now)
Update-Modules