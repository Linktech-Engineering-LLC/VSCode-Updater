<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-02
    Modified: 2026-07-05
    File: Get-VSCodeVersions.ps1
    Version: 1.1.0
    Description: Enumerates installed VS Code versions under LOCALAPPDATA\Programs,
                 validates folder integrity, and returns objects compatible with GUI DataGrid.
#>

function Get-VSCodeVersions {
    [CmdletBinding()]
    param()

    $root = Join-Path $env:LOCALAPPDATA "Programs"

    # Only match folders like VSCode-YYYYMMDD-HHMMSS
    $dirs = Get-ChildItem $root -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^VSCode-\d{8}-\d{6}$' } |
        Sort-Object Name -Descending

    $results = @()

    foreach ($dir in $dirs) {

        $path = $dir.FullName

        # Find Code.exe anywhere under the version folder
        $codeExe = Get-ChildItem -Path $path -Recurse -Filter "Code.exe" -ErrorAction SilentlyContinue |
                   Select-Object -First 1

        # Find product.json only in resources/app/product.json
        $productJson = Get-ChildItem -Path $path -Recurse -Filter "product.json" -ErrorAction SilentlyContinue |
                       Where-Object { $_.FullName -match 'resources\\app\\product\.json$' } |
                       Select-Object -First 1

        # Skip locked folders
        try {
            $null = Get-ChildItem $path -ErrorAction Stop
        }
        catch {
            Write-Log "[VERSIONS] Skipping locked folder: $path"
            continue
        }

        $isValid = ($codeExe -ne $null) -and ($productJson -ne $null)

        if (-not $isValid) {
            Write-Log "[VERSIONS] Invalid VS Code folder: $path"
        }

        $results += [PSCustomObject]@{
            Version        = $dir.Name
            Path           = $path
            LastModified   = $dir.LastWriteTime
            IsValid        = $isValid
            HasCodeExe     = ($codeExe -ne $null)
            HasProductJson = ($productJson -ne $null)
        }
    }

    return $results
}
