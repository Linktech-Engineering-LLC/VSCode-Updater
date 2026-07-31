<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-31
    Modified: 2026-07-31
    File: Private/Find-UserVSCode.ps1
    Version: 1.0.0
    Description: Description goes here
#>
function Find-UserVSCode {
    $root = Join-Path $env:LOCALAPPDATA "Programs"

    $folders = @(
        "Microsoft VS Code",
        "VSCode",
        "Code"
    )

    foreach ($folder in $folders) {
        $exe = Join-Path $root "$folder\Code.exe"
        if (Test-Path $exe) {
            return $exe
        }

        $exeBin = Join-Path $root "$folder\bin\Code.exe"
        if (Test-Path $exeBin) {
            return $exeBin
        }
    }

    # Symlink-based installs (your tooling)
    $symlink = Join-Path $root "VSCode\Current\Code.exe"
    if (Test-Path $symlink) {
        return $symlink
    }

    return $null
}

function Get-VSCodeInstallPath {
    $codeCmd = Get-Command code -ErrorAction SilentlyContinue
    if ($codeCmd -and $codeCmd.Source) {
        return (Split-Path $codeCmd.Source -Parent)
    }

    return "$env:LOCALAPPDATA\Programs\Microsoft VS Code"
}
