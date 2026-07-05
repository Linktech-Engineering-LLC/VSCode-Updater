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
function Cleanup-SetupBootstrapper {
    Write-Log "[CLEANUP] Checking for Setup bootstrapper processes"

    $setup = Get-Process -ErrorAction SilentlyContinue |
        Where-Object {
            # Direct bootstrapper names
            ($_.ProcessName -match "CodeSetup") -or
            ($_.ProcessName -match "VSCodeSetup") -or
            ($_.ProcessName -match "CodeUpdate") -or
            ($_.ProcessName -match "VSCodeUpdate") -or

            # Inno Setup workers (name only)
            ($_.ProcessName -match "^is-[A-Za-z0-9]+(\.tmp|\.tmp\.exe)?$") -or

            # Temp executables
            ($_.ProcessName -match "tmp$") -or
            ($_.ProcessName -match "tmp\.exe$") -or

            # Path-based detection (when available)
            ($_.Path -and ($_.Path -match "is-[A-Za-z0-9]+\.tmp")) -or
            ($_.Path -and ($_.Path -match "VSCodeSetup")) -or
            ($_.Path -and ($_.Path -match "CodeSetup")) -or

            # Command-line detection (covers PowerShell spawns)
            ($_.CommandLine -and ($_.CommandLine -match "is-[A-Za-z0-9]+\.tmp")) -or
            ($_.CommandLine -and ($_.CommandLine -match "VSCodeSetup")) -or
            ($_.CommandLine -and ($_.CommandLine -match "CodeSetup"))
        }

    # --- Double‑spawn diagnostics ---
    if ($setup.Count -gt 1) {
        Write-Log "[CLEANUP] Detected multiple bootstrapper workers: $($setup.Count)"
        $setup | ForEach-Object {
            Write-Log "[CLEANUP] Worker PID=$($_.Id) StartTime=$($_.StartTime)"
        }
    }
    # --------------------------------

    if ($setup) {
        Write-Log "[CLEANUP] Terminating bootstrapper PIDs: $($setup.Id -join ', ')"
        $setup | Stop-Process -Force -ErrorAction SilentlyContinue
    }
}
