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
function Clear-InnoSetupWorkers {
    Write-VSCodeUpdaterLog "[CLEANUP] Checking for InnoSetup workers"

    $parentPID = $script:CurrentInstallerPID

    # PHASE 1 — FAST SCAN
    $workers = Get-Process -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Id -ne $parentPID -and
            $_.Name -match '^is-[A-Za-z0-9]+(\.tmp|\.tmp\.exe)?$'
        }

    if ($workers) {
        Write-VSCodeUpdaterLog "[CLEANUP] Terminating InnoSetup worker PIDs (fast scan): $($workers.Id -join ', ')"
        $workers | Stop-Process -Force -ErrorAction SilentlyContinue
        return
    }

    # PHASE 2 — DEEP SCAN
    Write-VSCodeUpdaterLog "[CLEANUP] No InnoSetup workers found in fast scan — running deep scan"

    $candidates = Get-Process -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Id -ne $parentPID -and (
                $_.Name -match '^is-[A-Za-z0-9]+' -or
                $_.Name -match 'Setup'           -or
                $_.Name -match 'CodeSetup'       -or
                $_.Name -match 'VSCodeSetup'
            )
        }

    $workers = $candidates |
        Where-Object {
            ($_.Path        -and $_.Path        -match 'is-[A-Za-z0-9]+\.tmp') -or
            ($_.CommandLine -and $_.CommandLine -match 'is-[A-Za-z0-9]+\.tmp') -or
            ($_.CommandLine -and $_.CommandLine -match 'CodeSetup')            -or
            ($_.CommandLine -and $_.CommandLine -match 'VSCodeSetup')
        }

    if ($workers) {
        Write-VSCodeUpdaterLog "[CLEANUP] Terminating InnoSetup worker PIDs (deep scan): $($workers.Id -join ', ')"
        $workers | Stop-Process -Force -ErrorAction SilentlyContinue
    }
    else {
        Write-VSCodeUpdaterLog "[CLEANUP] No InnoSetup worker processes found"
    }
}
