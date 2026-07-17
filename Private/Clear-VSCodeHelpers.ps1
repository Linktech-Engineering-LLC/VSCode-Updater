<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-04-16
    Modified: 2026-04-16
    File: Private/Cleanup-VSCodeHelpers.ps1
    Version: 1.0.0
    Description: Terminates VS Code helper, setup, and orphaned installer processes to ensure a clean update state.
#>
function Clear-VSCodeHelpers {
    Write-VSCodeUpdaterLog "[CLEANUP] Checking for VS Code and installer helper processes"

    # Installer PID passed from Update-VSCode
    $installerPID = $script:CurrentInstallerPID

    #
    # PHASE 1 — FAST SCAN (names only)
    #
    $helpers = Get-Process -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Id -ne $installerPID -and (
                $_.Name -eq "Code"              -or
                $_.Name -like "CodeHelper*"     -or
                $_.Name -match "CodeSetup"      -or
                $_.Name -match "VSCodeSetup"    -or
                $_.Name -match "^is-[A-Za-z0-9]+(\.tmp|\.tmp\.exe)?$" -or
                $_.Name -match "tmp$"           -or
                $_.Name -match "tmp\.exe$"
            )
        }

    if ($helpers) {
        Write-VSCodeUpdaterLog "[CLEANUP] Terminating helper PIDs (fast scan): $($helpers.Id -join ', ')"
        $helpers | Stop-Process -Force -ErrorAction SilentlyContinue
        return
    }

    #
    # PHASE 2 — DEEP SCAN
    #
    Write-VSCodeUpdaterLog "[CLEANUP] No helper processes found in fast scan — running deep scan"

    $candidates = Get-Process -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Id -ne $installerPID -and (
                $_.Name -match "Code"       -or
                $_.Name -match "CodeHelper" -or
                $_.Name -match "Setup"      -or
                $_.Name -match "^is-[A-Za-z0-9]+"
            )
        }

    $helpers = $candidates |
        Where-Object {
            ($_.Path        -and $_.Path        -match "CodeSetup")          -or
            ($_.Path        -and $_.Path        -match "VSCodeSetup")        -or
            ($_.Path        -and $_.Path        -match "is-[A-Za-z0-9]+\.tmp") -or
            ($_.CommandLine -and $_.CommandLine -match "CodeSetup")          -or
            ($_.CommandLine -and $_.CommandLine -match "VSCodeSetup")        -or
            ($_.CommandLine -and $_.CommandLine -match "is-[A-Za-z0-9]+\.tmp")
        }

    if ($helpers) {
        Write-VSCodeUpdaterLog "[CLEANUP] Terminating helper PIDs (deep scan): $($helpers.Id -join ', ')"
        $helpers | Stop-Process -Force -ErrorAction SilentlyContinue
    }
    else {
        Write-VSCodeUpdaterLog "[CLEANUP] No VS Code helper processes found"
    }

    Out-Null
}
