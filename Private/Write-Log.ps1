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
    $fallback = Join-Path $logRoot "Update-Code.fallback.log"

    if (-not (Test-Path $logRoot)) {
        New-Item -ItemType Directory -Path $logRoot -Force | Out-Null
    }

    # Safe Mode prefix
    if ($script:SafeMode) {
        $Message = "[SAFE] $Message"
    }

    # Sanitize message
    $Message = $Message -replace "`r|`n", " "
    $Message = $Message.Trim()

    $timestamp = (Get-Date).ToString("yyyy-MM-dd HH:mm:ss")
    $line = "$timestamp $Message"

    # Retry logic
    for ($i = 1; $i -le 3; $i++) {
        try {
            Add-Content -Path $logFile -Value $line -ErrorAction Stop
            return
        }
        catch {
            Start-Sleep -Milliseconds 100
        }
    }

    # Fallback log
    try {
        Add-Content -Path $fallback -Value $line -ErrorAction SilentlyContinue
    }
    catch {
        # Last resort: write to host
        Write-Host $line
    }
}
