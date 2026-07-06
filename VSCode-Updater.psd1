<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-04-16
    Modified: 2026-06-14
    File: VSCode-Updater.psd1
    Version: 2.2.0
    Description: Module manifest defining metadata, versioning, and export configuration for the VSCode-Updater module.
#>
@{
    RootModule        = 'VSCode-Updater.psm1'
    ModuleVersion     = '2.2.0'
    GUID              = 'f2776614-4b50-45ba-b8fe-63875c447ab5'
    Author            = 'Leon McClatchey'
    CompanyName       = 'Linktech Engineering LLC'
    Description       = 'Deterministic, audit-transparent VS Code updater for Windows.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Update-VSCode',
        'Get-VSCodeVersions',
        'Switch-VSCodeVersion',
        'Invoke-VSCodeRollback',
        'Test-VSCodeSymlink',
        'Start-VSCodeSafeMode',
        'Get-VSCodeDashboard',
        'Invoke-ZipFallback',
        'Get-VSCodeSymlinkInfo',
        'Get-VSCodeLastResult',
        'Set-VSCodeSafeMode',
        'Start-VSCodeRepair',
        'Set-VSCodeSafeInstallerMode'
    )

    PrivateData = @{
        PSData = @{
            ProjectUri  = 'https://github.com/Linktech-Engineering-LLC/VSCode-Updater'
            LicenseUri  = 'https://github.com/Linktech-Engineering-LLC/VSCode-Updater/blob/main/LICENSE'
            IconUri     = 'https://raw.githubusercontent.com/Linktech-Engineering-LLC/VSCode-Updater/main/icon.png'
            Tags        = @('vscode','update','automation','windows','powershell','devtools')
            ReleaseNotes = 'Initial public release of VSCode-Updater.'
        }
    }
}
