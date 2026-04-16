<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-04-16
    Modified: 2026-04-16
    File: Private/Start-InstallerDetached.ps1
    Version: 1.0.0
    Description: Launches the VS Code installer as a fully detached process with no console inheritance to enable non-blocking update orchestration.
#>
function Start-InstallerDetached {
    param([string]$Path)

    Write-Log "[INSTALL] Launching installer detached: $Path"

    return Start-Process $Path `
        -ArgumentList '/VERYSILENT /NORESTART /MERGETASKS=!runcode' `
        -WindowStyle Hidden `
        -NoNewWindow:$false `
        -PassThru
}
