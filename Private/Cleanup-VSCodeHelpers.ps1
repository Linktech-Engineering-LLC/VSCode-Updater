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
function Cleanup-VSCodeHelpers {
    Write-Log "[CLEANUP] Checking for VS Code and installer helper processes"

    $procs = Get-Process -ErrorAction SilentlyContinue |
        Where-Object {
            # VS Code main process
            ($_.ProcessName -eq "Code") -or

            # VS Code helper processes (all variants)
            ($_.ProcessName -like "CodeHelper*") -or

            # Setup / installer processes
            ($_.ProcessName -match "CodeSetup") -or
            ($_.ProcessName -match "VSCodeSetup") -or
            ($_.ProcessName -match "Setup") -or
            ($_.ProcessName -match "Uninstall") -or

            # Temp-based helpers
            ($_.ProcessName -match "^is-[A-Za-z0-9]+(\.tmp|\.tmp\.exe)?$") -or
            ($_.ProcessName -match "tmp$") -or
            ($_.ProcessName -match "tmp\.exe$") -or

            # Path-based detection (when available)
            ($_.Path -and ($_.Path -match "CodeSetup")) -or
            ($_.Path -and ($_.Path -match "VSCodeSetup")) -or
            ($_.Path -and ($_.Path -match "is-[A-Za-z0-9]+\.tmp")) -or

            # Command-line detection (covers PowerShell spawns)
            ($_.CommandLine -and ($_.CommandLine -match "CodeSetup")) -or
            ($_.CommandLine -and ($_.CommandLine -match "VSCodeSetup")) -or
            ($_.CommandLine -and ($_.CommandLine -match "is-[A-Za-z0-9]+\.tmp"))
        }

    if ($procs) {
        Write-Log "[CLEANUP] Terminating helper PIDs: $($procs.Id -join ', ')"
        $procs | Stop-Process -Force -ErrorAction SilentlyContinue
    }
}
