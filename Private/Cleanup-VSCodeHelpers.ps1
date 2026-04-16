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

    $targets = @(
        "Code",
        "CodeHelper",
        "CodeHelperCP",
        "CodeHelperRenderer",
        "CodeHelperWebView",
        "CodeHelperGPU",
        "CodeSetup",
        "Setup",
        "Uninstall",
        "VSCodeSetup",
        "VSCodeSetup.tmp"
    )

    foreach ($t in $targets) {
        $procs = Get-Process -Name $t -ErrorAction SilentlyContinue
        if ($procs) {
            Write-Log "[CLEANUP] Terminating $t PIDs: $($procs.Id -join ', ')"
            $procs | Stop-Process -Force -ErrorAction SilentlyContinue
        }
    }
}
