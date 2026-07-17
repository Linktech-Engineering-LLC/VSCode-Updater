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
function Invoke-InstallerDetached {
    [OutputType([System.Diagnostics.Process])]
    [CmdletBinding()]
    param([string]$Path)

    # Prevent multiple installers
    $existing = Get-Process -Name "VSCodeSetup" -ErrorAction SilentlyContinue
    if ($existing) {
        throw [ExistingInstallerDetectedException]::new(
            "Existing installer detected (PID=$($existing.Id))"
        )
    }

    if ($script:SafeMode) {
        throw [InstallerException]::new("SAFE MODE — Installer launch skipped.")
    }

    if (-not (Test-Path $Path)) {
        throw [InstallerNotFoundException]::new("Installer not found: $Path")
    }

    if (Get-Process -Name "Code" -ErrorAction SilentlyContinue) {
        $choice = Read-Host "VS Code is running. Close it before continuing? (Y/N)"
        if ($choice -notin @('Y','y')) {
            throw [VSCodeRunningUserDeclinedException]::new(
                "User declined to close VS Code"
            )
        }
        Get-Process -Name "Code" | Stop-Process -Force
    }

    $info = Get-Item $Path -ErrorAction SilentlyContinue
    if ($info.Extension -ne ".exe") {
        throw [InvalidInstallerExtensionException]::new(
            "Invalid installer extension: $($info.Extension)"
        )
    }

    if ($info.Length -lt 1MB) {
        throw [InstallerTooSmallException]::new(
            "Installer too small (<1MB): $Path"
        )
    }

    $rc = '/VERYSILENT /NORESTART /MERGETASKS=!runcode'
    Write-VSCodeUpdaterLog "[INSTALL] Launching installer detached"
    Write-VSCodeUpdaterLog "[INSTALL] Command: `"$Path`" $rc"

    try {
        $proc = Start-Process $Path `
            -ArgumentList $rc `
            -WindowStyle Hidden `
            -NoNewWindow:$false `
            -PassThru `
            -ErrorAction Stop
    }
    catch {
        throw [InstallerLaunchFailedException]::new(
            "Failed to launch installer: $($_.Exception.Message)"
        )
    }

    Write-VSCodeUpdaterLog "[INSTALL] Installer launched (PID=$($proc.Id))"
    return $proc
}
