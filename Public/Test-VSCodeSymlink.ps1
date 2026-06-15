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
        Write-Log "[VALIDATE] Link missing"
        return $false
    }

    $item = Get-Item $linkPath -ErrorAction SilentlyContinue
    if ($null -eq $item) {
        Write-Log "[VALIDATE] Link path exists but could not be resolved"
        return $false
    }

    # Accept both SymbolicLink and Junction
    if ($item.LinkType -notin @("SymbolicLink", "Junction")) {
        Write-Log "[VALIDATE] Path exists but is not a symlink or junction (LinkType=$($item.LinkType))"
        return $false
    }

    $target = $item.Target
    if (-not (Test-Path $target)) {
        Write-Log "[VALIDATE] Link target missing: $target"
        return $false
    }

    $codeExe = Join-Path $target "Code.exe"
    if (-not (Test-Path $codeExe)) {
        Write-Log "[VALIDATE] Code.exe missing in target"
        return $false
    }

    Write-Log "[VALIDATE] Link OK ($($item.LinkType)) → $target"
    return $true
}
