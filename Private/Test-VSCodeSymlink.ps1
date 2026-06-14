<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-06-14
    Modified: 2026-06-14
    File: Test-VSCodeSymlink.ps1
    Version: 1.0.0
    Description: Description goes here
#>

function Test-VSCodeSymlink {
    [CmdletBinding()]
    param()

    $root = Join-Path $env:LOCALAPPDATA "Programs"
    $linkPath = Join-Path $root "Microsoft VS Code"

    if (-not (Test-Path $linkPath)) {
        Write-Log "[VALIDATE] Symlink missing"
        return $false
    }

    $item = Get-Item $linkPath -ErrorAction SilentlyContinue

    if ($item.LinkType -ne "SymbolicLink") {
        Write-Log "[VALIDATE] Path exists but is not a symlink"
        return $false
    }

    $target = $item.Target

    if (-not (Test-Path $target)) {
        Write-Log "[VALIDATE] Symlink target missing: $target"
        return $false
    }

    $codeExe = Join-Path $target "Code.exe"
    if (-not (Test-Path $codeExe)) {
        Write-Log "[VALIDATE] Code.exe missing in target"
        return $false
    }

    Write-Log "[VALIDATE] Symlink OK → $target"
    return $true
}
