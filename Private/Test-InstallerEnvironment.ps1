<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-06
    Modified: 2026-07-06
    File: Test-InstallerEnvironment.ps1
    Version: 1.0.0
    Description: Description goes here
#>
function Test-InstallerEnvironment {
    [CmdletBinding()]
    param()

    $issues = @()

    $installRoot = "$env:LOCALAPPDATA\Programs\Microsoft VS Code"
    if (Test-Path $installRoot) {
        $issues += "[CHECK] Existing install root present: $installRoot"
    }

    $msiKey = "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Installer\InProgress"
    if (Test-Path $msiKey) {
        $issues += "[CHECK] MSI InProgress key present"
    }

    $wv2 = "$env:LOCALAPPDATA\Microsoft\EdgeWebView"
    if (Test-Path $wv2) {
        $issues += "[CHECK] WebView2 runtime present: $wv2"
    }

    foreach ($i in $issues) { Write-Log $i }

    return $issues
}
