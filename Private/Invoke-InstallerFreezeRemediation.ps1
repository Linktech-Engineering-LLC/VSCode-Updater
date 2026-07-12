<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-06
    Modified: 2026-07-06
    File: Invoke-InstallerFreezeRemediation.ps1
    Version: 1.0.0
    Description: Description goes here
#>
function Invoke-InstallerFreezeRemediation {
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

    # 2. VS Code install root — REMOVE ONLY KNOWN DEBRIS
    $installRoot = "$env:LOCALAPPDATA\Programs\Microsoft VS Code"
    if (Test-Path $installRoot) {
        try {
            Write-Log "[FIX] Cleaning VS Code install root debris (preserving valid files)"

            $debris = @(
                "update.exe",
                "*.tmp",
                "*.partial",
                "is-*.tmp",
                "is-*.bin",
                "innosetup.tmp",
                "new_*",
                "tmp_*",
                "partial_*"
            )

            foreach ($pattern in $debris) {
                Get-ChildItem -Path $installRoot -Filter $pattern -ErrorAction SilentlyContinue |
                    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        catch {
            Write-Log "[WARN] Failed to clean install root debris: $($_.Exception.Message)"
        }
    }

    # 3. WebView2 runtime — CLEAN WEBVIEW2, NOT VS CODE
    $wv2 = "$env:LOCALAPPDATA\Microsoft\EdgeWebView"
    if (Test-Path $wv2) {
        try {
            Write-Log "[FIX] Resetting WebView2 runtime: $wv2"
            Get-ChildItem $wv2 -Force -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
        catch {
            Write-Log "[WARN] Failed to reset WebView2 runtime: $($_.Exception.Message)"
        }
    }

    Write-Log "[FIX] Installer freeze remediation completed"
}
