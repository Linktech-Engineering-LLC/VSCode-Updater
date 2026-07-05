<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-03
    Modified: 2026-07-05
    File: PostUpdateCheck.ps1
    Version: 1.1.0
    Description:
        Lightweight verification script for VSCode-Updater environments.
        Checks:
        1. VSCODE_PATH environment variable
        2. Log file existence and writeability
        3. PowerShell profile load health
#>

# Ensure _out is available (GUI loads the module before launching this script)
if (-not (Get-Command _out -ErrorAction SilentlyContinue)) {
    function _out { param($m,$c) Write-Host $m -ForegroundColor $c }
}

_out "=== VSCode Post-Update Verification ===" "Cyan"

# --- 1. Check VSCODE_PATH -----------------------------------------------
if (-not $env:VSCODE_PATH) {
    _out "[FAIL] VSCODE_PATH is not set" "Red"
}
elseif (-not (Test-Path $env:VSCODE_PATH)) {
    _out "[FAIL] VSCODE_PATH points to a missing directory: $env:VSCODE_PATH" "Red"
}
else {
    _out "[OK] VSCODE_PATH is valid: $env:VSCODE_PATH" "Green"
}

# --- 2. Check log file ---------------------------------------------------
$logFile = Join-Path $env:VSCODE_PATH "Logs\VSCode-Updater.log"

if (-not (Test-Path $logFile)) {
    _out "[WARN] Log file does not exist yet: $logFile" "Yellow"
}
else {
    try {
        Add-Content -Path $logFile -Value "`n# Post-update check at $(Get-Date)" -ErrorAction Stop
        _out "[OK] Log file is writable: $logFile" "Green"
    }
    catch {
        _out "[FAIL] Log file exists but is not writable: $logFile" "Red"
    }
}

# --- 3. Check PowerShell profile ----------------------------------------
try {
    . $PROFILE
    _out "[OK] PowerShell profile loaded successfully" "Green"
}
catch {
    _out "[FAIL] Error loading PowerShell profile: $($_.Exception.Message)" "Red"
}

_out "=== Verification Complete ===" "Cyan"
