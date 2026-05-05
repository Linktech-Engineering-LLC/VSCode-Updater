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
    ModuleVersion     = '2.0.1'
    GUID              = 'f2776614-4b50-45ba-b8fe-63875c447ab5'
    Author            = 'Leon McClatchey'
    CompanyName       = 'Linktech Engineering LLC'
    Description       = 'Deterministic, audit-transparent VS Code updater for Windows.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @('Update-VSCode')

    ProjectUri        = 'https://github.com/Linktech-Engineering-LLC/VSCode-Updater'
    LicenseUri        = 'https://github.com/Linktech-Engineering-LLC/VSCode-Updater/blob/main/LICENSE'
    IconUri           = 'https://raw.githubusercontent.com/Linktech-Engineering-LLC/VSCode-Updater/main/icon.png'
    Tags              = @('vscode','update','automation','windows','powershell','devtools')
    ReleaseNotes      = 'Initial public release of VSCode-Updater.'

    PrivateData       = @{}
}
