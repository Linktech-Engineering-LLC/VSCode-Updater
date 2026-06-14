<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-06-14
    Modified: 2026-06-14
    File: Start-VSCodeSafeMode.ps1
    Version: 1.0.0
    Description: Description goes here
#>

function Start-VSCodeSafeMode {
    [CmdletBinding()]
    param()

    $codeExe = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"

    if (-not (Test-Path $codeExe)) {
        Write-Log "[SAFE] Code.exe not found"
        return 70
    }

    Write-Log "[SAFE] Launching VS Code in safe mode"

    Start-Process $codeExe -ArgumentList @(
        "--disable-extensions",
        "--disable-gpu",
        "--disable-workspace-trust",
        "--disable-crash-reporter",
        "--disable-telemetry",
        "--user-data-dir", "`"$env:TEMP\VSCodeSafeMode`""
    )
}
