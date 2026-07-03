<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-03
    Modified: 2026-07-03
    File: PostUpdateCheck.ps1
    Version: 1.0.0
    Description: 
                Lightweight verification script for VSCode-Updater environments.
                Checks:
                1. VSCODE_PATH environment variable
                2. Log file existence and writeability
                3. PowerShell profile load health
#>

Write-Host "=== VSCode Post-Update Verification ===" -ForegroundColor Cyan

# --- 1. Check VSCODE_PATH -----------------------------------------------
if (-not $env:VSCODE_PATH) {
    Write-Host "[FAIL] VSCODE_PATH is not set" -ForegroundColor Red
} elseif (-not (Test-Path $env:VSCODE_PATH)) {
    Write-Host "[FAIL] VSCODE_PATH points to a missing directory: $env:VSCODE_PATH" -ForegroundColor Red
} else {
    Write-Host "[OK] VSCODE_PATH is valid: $env:VSCODE_PATH" -ForegroundColor Green
}

# --- 2. Check log file ---------------------------------------------------
$logFile = Join-Path $env:VSCODE_PATH "Logs\VSCode-Updater.log"

if (-not (Test-Path $logFile)) {
    Write-Host "[WARN] Log file does not exist yet: $logFile" -ForegroundColor Yellow
} else {
    try {
        Add-Content -Path $logFile -Value "`n# Post-update check at $(Get-Date)" -ErrorAction Stop
        Write-Host "[OK] Log file is writable: $logFile" -ForegroundColor Green
    }
    catch {
        Write-Host "[FAIL] Log file exists but is not writable: $logFile" -ForegroundColor Red
    }
}

# --- 3. Check PowerShell profile ----------------------------------------
try {
    # Load the profile in a child scope to avoid polluting the session
    . $PROFILE
    Write-Host "[OK] PowerShell profile loaded successfully" -ForegroundColor Green
}
catch {
    Write-Host "[FAIL] Error loading PowerShell profile: $($_.Exception.Message)" -ForegroundColor Red
}

Write-Host "=== Verification Complete ===" -ForegroundColor Cyan
