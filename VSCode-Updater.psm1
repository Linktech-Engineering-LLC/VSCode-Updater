<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-04-16
    Modified: 2026-04-16
    File: VSCode-Updater.psm1
    Version: 1.0.0
    Description: Module root for VSCode-Updater. Loads public functions, wires private helpers, and exposes the deterministic Update-VSCode entry point.
#>
# Load private functions
Get-ChildItem -Path "$PSScriptRoot/Private" -Filter *.ps1 |
    ForEach-Object { . $_.FullName }

# Load public functions
Get-ChildItem -Path "$PSScriptRoot/Public" -Filter *.ps1 |
    ForEach-Object { . $_.FullName }

Export-ModuleMember -Function Update-VSCode
