<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-04-16
    Modified: 2026-04-16
    File: VSCode-Updater.psd1
    Version: 1.0.0
    Description: Module manifest defining metadata, versioning, and export configuration for the VSCode-Updater module.
#>
@{
    RootModule        = 'VSCode-Updater.psm1'
    ModuleVersion     = '1.0.0'
    GUID              = '00000000-0000-0000-0000-000000000000'
    Author            = 'Leon McClatchey'
    CompanyName       = 'Linktech Engineering LLC'
    Description       = 'Deterministic, audit-transparent VS Code updater for Windows.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @('Update-VSCode')
    PrivateData       = @{}
}
