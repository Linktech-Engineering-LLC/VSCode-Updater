<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-04-16
    Modified: 2026-04-16
    File: Private/Cleanup-InnoSetupWorkers.ps1
    Version: 1.0.0
    Description: Detects and terminates active Inno Setup worker and bootstrapper processes to prevent installer hangs.
#>
function Cleanup-InnoSetupWorkers {
    Write-Log "[CLEANUP] Checking for InnoSetup workers"

    $workers = Get-Process -ErrorAction SilentlyContinue |
        Where-Object {
            # Some workers have no path at all
            ($_.ProcessName -match '^is-[A-Za-z0-9]+(\.tmp|\.tmp\.exe)?$') -or
            ($_.Path -and ($_.Path -match 'is-[A-Za-z0-9]+\.tmp')) -or
            ($_.CommandLine -and ($_.CommandLine -match 'is-[A-Za-z0-9]+\.tmp'))
        }

    if ($workers) {
        Write-Log "[CLEANUP] Terminating InnoSetup worker PIDs: $($workers.Id -join ', ')"
        $workers | Stop-Process -Force -ErrorAction SilentlyContinue
    }

    # Also catch CodeSetup helpers (consistent with your other cleanup script)
    $helpers = Get-Process -ErrorAction SilentlyContinue |
        Where-Object {
            ($_.ProcessName -eq 'VSCodeSetup.tmp') -or
            ($_.CommandLine -match 'CodeSetup') -or
            ($_.CommandLine -match 'VSCodeSetup')
        }

    if ($helpers) {
        Write-Log "[CLEANUP] Terminating VS Code installer helpers: $($helpers.Id -join ', ')"
        $helpers | Stop-Process -Force -ErrorAction SilentlyContinue
    }
}
