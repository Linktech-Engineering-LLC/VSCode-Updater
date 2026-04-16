<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-04-16
    Modified: 2026-04-16
    File: Private/Get-FileHashSafe.ps1
    Version: 1.0.0
    Description: Computes a SHA256 hash for a file with safe error handling, returning $null on failure.
#>
function Get-FileHashSafe {
    param([string]$Path)

    if (-not (Test-Path $Path)) { return $null }

    try {
        return (Get-FileHash -Algorithm SHA256 -Path $Path).Hash
    }
    catch {
        Write-Log "[ERROR] Failed to compute hash for $Path : $($_.Exception.Message)"
        return $null
    }
}
