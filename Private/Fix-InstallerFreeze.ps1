<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-06
    Modified: 2026-07-06
    File: Fix-InstallerFreeze.ps1
    Version: 1.0.0
    Description: Description goes here
#>
function Fix-InstallerFreeze {
    [CmdletBinding()]
    param()

    Write-Log "[FIX] Running installer freeze remediation"

    # 1. MSI InProgress key
    $msiKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\InProgress"
    if (Test-Path $msiKey) {
        try {
            Remove-Item $msiKey -Force -Recurse -ErrorAction Stop
            Write-Log "[FIX] Removed MSI InProgress key"
        }
        catch {
            Write-Log "[WARN] Failed to remove MSI InProgress key: $($_.Exception.Message)"
        }
    }

    # 2. VS Code install root
    $installRoot = "$env:LOCALAPPDATA\Programs\Microsoft VS Code"
    if (Test-Path $installRoot) {
        try {
            Write-Log "[FIX] Removing existing VS Code install root: $installRoot"
            Remove-Item $installRoot -Force -Recurse -ErrorAction Stop
        }
        catch {
            Write-Log "[WARN] Failed to remove install root: $($_.Exception.Message)"
        }
    }

    # 3. WebView2 runtime
    $wv2 = "$env:LOCALAPPDATA\Microsoft\EdgeWebView"
    if (Test-Path $wv2) {
        try {
            Write-Log "[FIX] Resetting WebView2 runtime: $wv2"
            Remove-Item $wv2 -Force -Recurse -ErrorAction Stop
        }
        catch {
            Write-Log "[WARN] Failed to reset WebView2 runtime: $($_.Exception.Message)"
        }
    }

    Write-Log "[FIX] Installer freeze remediation completed"
}
