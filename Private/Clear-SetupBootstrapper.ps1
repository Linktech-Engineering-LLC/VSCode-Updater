<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-04-16
    Modified: 2026-05-07
    File: Private/Cleanup-SetupBootstrapper.ps1
    Version: 1.0.1
    Description: Terminates VS Code setup bootstrapper processes to ensure a clean update state.
#>
function Clear-SetupBootstrapper {
    Write-Log "[CLEANUP] Checking for Setup bootstrapper processes"

    #
    # PHASE 1 — FAST DETECTION (names only)
    # This avoids touching protected processes and eliminates the 120‑second stall.
    #
    $setup = Get-Process -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -match "CodeSetup"      -or
            $_.Name -match "VSCodeSetup"    -or
            $_.Name -match "CodeUpdate"     -or
            $_.Name -match "VSCodeUpdate"   -or
            $_.Name -match "^is-[A-Za-z0-9]+(\.tmp|\.tmp\.exe)?$" -or
            $_.Name -match "tmp$"           -or
            $_.Name -match "tmp\.exe$"
        }

    if ($setup) {
        Write-Log "[CLEANUP] Found bootstrapper processes (fast scan) — terminating"
        $setup | Stop-Process -Force
        return
    }

    #
    # PHASE 2 — SLOW DETECTION (path + command line)
    # Only runs if Phase 1 found nothing. This avoids hitting protected processes every run.
    #
    Write-Log "[CLEANUP] No bootstrapper processes found in fast scan — running deep scan"

	# Candidate processes based on name only
	$candidates = Get-Process -ErrorAction SilentlyContinue |
		Where-Object {
			$_.Name -match "setup" -or
			$_.Name -match "update" -or
			$_.Name -match "^is-[A-Za-z0-9]+"
		}

	$setup = $candidates |
		Where-Object {
			($_.Path        -and $_.Path        -match "VSCodeSetup")          -or
			($_.Path        -and $_.Path        -match "CodeSetup")            -or
			($_.Path        -and $_.Path        -match "is-[A-Za-z0-9]+\.tmp") -or
			($_.CommandLine -and $_.CommandLine -match "VSCodeSetup")          -or
			($_.CommandLine -and $_.CommandLine -match "CodeSetup")            -or
			($_.CommandLine -and $_.CommandLine -match "is-[A-Za-z0-9]+\.tmp")
		}

    if ($setup) {
        Write-Log "[CLEANUP] Found bootstrapper processes (deep scan) — terminating"
        $setup | Stop-Process -Force
    }
    else {
        Write-Log "[CLEANUP] No setup bootstrapper processes found"
    }
	Out-Null
}
