<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-04-16
    Modified: 2026-04-16
    File: Private/Cleanup-SetupBootstrapper.ps1
    Version: 1.0.0
    Description: Terminates VS Code setup bootstrapper processes to ensure a clean update state.
#>
function Cleanup-SetupBootstrapper {
    Write-Log "[CLEANUP] Checking for Setup bootstrapper processes"

    $setup = Get-Process -ErrorAction SilentlyContinue |
        Where-Object {
            $_.ProcessName -match "CodeSetup" -or
            $_.ProcessName -match "VSCodeSetup" -or
            $_.ProcessName -match "^is-[A-Za-z0-9]+" -or
            $_.ProcessName -match "tmp$" -or
            $_.ProcessName -match "tmp.exe$" -or
            $_.ProcessName -match "CodeUpdate*" -or
            $_.ProcessName -match "VSCodeUpdate*"
        }

    if ($setup) {
        Write-Log "[CLEANUP] Terminating bootstrapper PIDs: $($setup.Id -join ', ')"
        $setup | Stop-Process -Force -ErrorAction SilentlyContinue
    }
}
