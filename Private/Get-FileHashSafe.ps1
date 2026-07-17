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
    [OutputType([string])]
    param([string]$Path)

    if (-not (Test-Path $Path)) {
        Write-VSCodeUpdaterLog "[HASH] File not found: $Path"
        return $null
    }

    # --- Hydration attempt (OneDrive / cloud providers) ---
    try {
        $stream = [System.IO.File]::Open($Path, 'Open', 'Read', 'None')
        $stream.Close()
    }
    catch {
        $null = Write-VSCodeUpdaterLog "[HASH] Hydration attempt failed for $Path : $($_.Exception.Message)"
    }

    # --- First attempt ---
    try {
        return (Get-FileHash -Algorithm SHA256 -Path $Path).Hash
    }
    catch {
        Write-VSCodeUpdaterLog "[HASH] First hash attempt failed for $Path : $($_.Exception.Message)"
    }

    # --- Retry after short delay ---
    Start-Sleep -Milliseconds 150
    try {
        return (Get-FileHash -Algorithm SHA256 -Path $Path).Hash
    }
    catch {
        Write-VSCodeUpdaterLog "[HASH] Second hash attempt failed for $Path : $($_.Exception.Message)"
    }

    # --- Manual fallback hashing ---
    try {
        $sha = [System.Security.Cryptography.SHA256]::Create()
        $stream = [System.IO.File]::OpenRead($Path)
        $hashBytes = $sha.ComputeHash($stream)
        $stream.Close()

        return ([BitConverter]::ToString($hashBytes) -replace "-", "").ToLower()
    }
    catch {
        Write-VSCodeUpdaterLog "[HASH] Manual SHA256 fallback failed for $Path : $($_.Exception.Message)"
        return $null
    }
}
