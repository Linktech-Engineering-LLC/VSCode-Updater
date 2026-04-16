<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-04-16
    Modified: 2026-04-16
    File: Private/CleanCodePath.ps1
    Version: 1.0.0
    Description: Cleans and normalizes the VSCode installer path before update operations.
#>
function CleanCodePath {
    param([string]$Path = "$env:LOCALAPPDATA\Programs\Microsoft VS Code")

    Write-Log "[CLEANUP] Cleaning VS Code debris in: $Path"

    if (-not (Test-Path $Path)) {
        Write-Log "[CLEANUP] VS Code path not found — skipping."
        return
    }

    $lockFiles = Get-ChildItem -Path $Path -Filter "is-*.tmp" -ErrorAction SilentlyContinue
    foreach ($file in $lockFiles) {
        Write-Log "[CLEANUP] Removing lock file: $($file.Name)"
        Remove-Item $file.FullName -Force -ErrorAction SilentlyContinue
    }

    $hashFolders = Get-ChildItem -Path $Path -Directory |
        Where-Object { $_.Name -match '^[a-f0-9]{8,}$' }

    foreach ($folder in $hashFolders) {
        Write-Log "[CLEANUP] Removing leftover folder: $($folder.Name)"
        Remove-Item $folder.FullName -Recurse -Force -ErrorAction SilentlyContinue
    }

    $partialExe = Get-ChildItem -Path $Path -Filter "new_code.exe" -ErrorAction SilentlyContinue
    foreach ($exe in $partialExe) {
        Write-Log "[CLEANUP] Removing partial executable: $($exe.Name)"
        Remove-Item $exe.FullName -Force -ErrorAction SilentlyContinue
    }

    Write-Log "[CLEANUP] VS Code cleanup complete."
}
