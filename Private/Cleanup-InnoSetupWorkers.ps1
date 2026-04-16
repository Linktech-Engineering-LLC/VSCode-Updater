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
        Where-Object { $_.Path -like "$env:TEMP\is-*.tmp" }

    if ($workers) {
        Write-Log "[CLEANUP] Terminating InnoSetup worker PIDs: $($workers.Id -join ', ')"
        $workers | Stop-Process -Force -ErrorAction SilentlyContinue
    }
}
