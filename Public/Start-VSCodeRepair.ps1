<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-06
    Modified: 2026-07-06
    File: Start-VSCodeRepair.ps1
    Version: 1.0.0
    Description: Description goes here
#>
function Start-VSCodeRepair {
    [CmdletBinding()]
    param(
        [switch]$DryRun
    )

    Write-VSCodeUpdaterLog "[REPAIR] VS Code repair requested (DryRun=$($DryRun.IsPresent))"

    $issues = Test-InstallerEnvironment

    if ($DryRun) {
        Write-VSCodeUpdaterLog "[REPAIR] Dry run only — no changes applied"
        return $issues
    }

    Fix-InstallerFreeze

    Write-VSCodeUpdaterLog "[REPAIR] Environment repaired — you may re-run Update-VSCode"
    return $issues
}
