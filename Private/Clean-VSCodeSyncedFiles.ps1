<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-17
    Modified: 2026-07-17
    File: Private/Clean-VSCodeSyncedFiles.ps1
    Version: 1.0.0
    Description: Description goes here
#>
function Clean-VSCodeSyncedFiles {
    [CmdletBinding()]
    param()

    if ($script:SafeMode) {
        Write-VSCodeUpdaterLog "[CLEANUP] SAFE MODE — synced files cleanup skipped"
        return
    }

    Write-VSCodeUpdaterLog "[CLEANUP] Starting synced files cleanup"

    $appData = Join-Path $env:APPDATA "Code"
    $localData = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code"

    $cachedData = Join-Path $appData "CachedData"
    if (Test-Path $cachedData) {
        Write-VSCodeUpdaterLog "[CLEANUP] Removing CachedData"
        Remove-Item $cachedData -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }

    $cachedExt = Join-Path $appData "CachedExtensions"
    if (Test-Path $cachedExt) {
        Write-VSCodeUpdaterLog "[CLEANUP] Removing CachedExtensions"
        Remove-Item $cachedExt -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }

    $logs = Join-Path $appData "logs"
    if (Test-Path $logs) {
        Write-VSCodeUpdaterLog "[CLEANUP] Removing logs"
        Remove-Item $logs -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }

    $backups = Join-Path $appData "Backups"
    if (Test-Path $backups) {
        Write-VSCodeUpdaterLog "[CLEANUP] Removing Backups"
        Remove-Item $backups -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }

    $crashpad = Join-Path $appData "Crashpad"
    if (Test-Path $crashpad) {
        Write-VSCodeUpdaterLog "[CLEANUP] Removing Crashpad"
        Remove-Item $crashpad -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }

    $tmpExe = Join-Path $localData "Code.exe.tmp"
    if (Test-Path $tmpExe) {
        Write-VSCodeUpdaterLog "[CLEANUP] Removing Code.exe.tmp"
        Remove-Item $tmpExe -Force -ErrorAction SilentlyContinue | Out-Null
    }

    $partials = Get-ChildItem $localData -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^app-\d+\.\d+\.\d+-\d+$' }

    foreach ($p in $partials) {
        Write-VSCodeUpdaterLog "[CLEANUP] Removing partial install folder: $($p.FullName)"
        Remove-Item $p.FullName -Recurse -Force -ErrorAction SilentlyContinue | Out-Null
    }

    $stale = Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^CodeHelper|^tmp$|tmp\.exe$|^is-[A-Za-z0-9]+' }

    foreach ($proc in $stale) {
        Write-VSCodeUpdaterLog "[CLEANUP] Killing stale process: $($proc.Name) (PID $($proc.Id))"
        Stop-Process -Id $proc.Id -Force -ErrorAction SilentlyContinue | Out-Null
    }

    Write-VSCodeUpdaterLog "[CLEANUP] Synced files cleanup completed"
}
