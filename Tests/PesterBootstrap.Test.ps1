
<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-05
    Modified: 2026-07-05
    File: PesterBootstrap.ps1
    Version: 1.0.0
    Description: Description goes here
#>
# Tests\PesterBootstrap.ps1
# Loads the VSCode-Updater module BEFORE Pester discovers tests.

$modulePath = Join-Path $PSScriptRoot "..\VSCode-Updater.psd1"

if (-not (Test-Path $modulePath)) {
    throw "Module manifest not found at: $modulePath"
}

Import-Module $modulePath -Force

# Now run Pester normally
Invoke-Pester -Path $PSScriptRoot
