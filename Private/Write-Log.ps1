<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-04-16
    Modified: 2026-04-16
    File: Private/Write-Log.ps1
    Version: 1.0.0
    Description: Writes timestamped log entries to the VSCode-Updater log file with deterministic formatting.
#>
function Write-Log {
    param([string]$Message)

    $logRoot = "C:\Logs"
    $logFile = Join-Path $logRoot "Update-Code.log"

    if (-not (Test-Path $logRoot)) {
        New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
    }

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    Add-Content -Path $logFile -Value "$timestamp $Message"
}
