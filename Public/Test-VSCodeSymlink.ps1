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

    if ($script:SafeMode) {
        Write-VSCodeUpdaterLog "[VALIDATE] SAFE MODE — Symlink validation skipped"
        return $true
    }

    $root     = Join-Path $env:LOCALAPPDATA "Programs"
    $linkPath = Join-Path $root "Microsoft VS Code"

    if (-not (Test-Path $linkPath)) {
        Write-VSCodeUpdaterLog "[VALIDATE] Link missing: $linkPath"
        return $false
    }

    $item = Get-Item $linkPath -ErrorAction SilentlyContinue
    if (-not $item) {
        Write-VSCodeUpdaterLog "[VALIDATE] Link exists but cannot be resolved"
        return $false
    }

    Write-VSCodeUpdaterLog "[VALIDATE] LinkType detected: $($item.LinkType)"

    # Accept both symbolic links and junctions
    if ($item.LinkType -notin @("SymbolicLink", "Junction")) {
        Write-VSCodeUpdaterLog "[VALIDATE] Invalid LinkType: $($item.LinkType)"
        return $false
    }

    # Extract target (symlink or junction)
    $target = $item.Target
    if (-not $target) {
        Write-VSCodeUpdaterLog "[VALIDATE] Link target is null or empty"
        return $false
    }

    if (-not (Test-Path $target)) {
        Write-VSCodeUpdaterLog "[VALIDATE] Link target missing: $target"
        return $false
    }

    # Validate folder structure
    $codeExe     = Join-Path $target "Code.exe"
    $resources   = Join-Path $target "resources"
    $productJson = Join-Path $resources "app\product.json"

    if (-not (Test-Path $codeExe)) {
        Write-VSCodeUpdaterLog "[VALIDATE] Code.exe missing in target: $target"
        return $false
    }
    if (-not (Test-Path $resources)) {
        Write-VSCodeUpdaterLog "[VALIDATE] resources folder missing in target: $target"
        return $false
    }
    if (-not (Test-Path $productJson)) {
        Write-VSCodeUpdaterLog "[VALIDATE] product.json missing in target: $target"
        return $false
    }

    # Detect locked folders
    try {
        $null = Get-ChildItem $target -ErrorAction Stop
    }
    catch {
        Write-VSCodeUpdaterLog "[VALIDATE] Target folder is locked or inaccessible: $target"
        return $false
    }

    Write-VSCodeUpdaterLog "[VALIDATE] Link OK ($($item.LinkType)) → $target"
    return $true
}
