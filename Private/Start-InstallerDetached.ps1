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
    [CmdletBinding()]
    param([string]$Path)

    if ($script:SafeMode) {
        _out "SAFE MODE — Installer launch skipped." "Yellow"
        return 0
    }

    if (-not (Test-Path $Path)) {
        Write-Log "[INSTALL] Installer not found: $Path"
        return 80
    }

    $info = Get-Item $Path -ErrorAction SilentlyContinue
    if ($info.Extension -ne ".exe") {
        Write-Log "[INSTALL] Invalid installer extension: $($info.Extension)"
        return 81
    }
    if ($info.Length -lt 1MB) {
        Write-Log "[INSTALL] Installer too small (<1MB): $Path"
        return 82
    }

    $args = '/VERYSILENT /NORESTART /MERGETASKS=!runcode'
    Write-Log "[INSTALL] Launching installer detached"
    Write-Log "[INSTALL] Command: `"$Path`" $args"

    try {
        $proc = Start-Process $Path `
            -ArgumentList $args `
            -WindowStyle Hidden `
            -NoNewWindow:$false `
            -PassThru `
            -ErrorAction Stop
    }
    catch {
        Write-Log "[ERROR] Failed to launch installer: $($_.Exception.Message)"
        return 83
    }

	Write-Log "[INSTALL] Installer launched (PID=$($proc.Id))"
	return $proc
}
