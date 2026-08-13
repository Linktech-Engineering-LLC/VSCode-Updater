<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-04-16
    Modified: 2026-06-14
    File: VSCode-Updater.psd1
    Version: 3.1.0
    Description: Module manifest defining metadata, versioning, and export configuration for the VSCode-Updater module.
#>
@{
    RootModule = 'VSCode-Updater.psm1'
    ModuleVersion = '3.1.0'
    GUID = 'f2776614-4b50-45ba-b8fe-63875c447ab5'
    Author = 'Leon McClatchey'
    CompanyName = 'Linktech Engineering LLC'
    Description = 'Deterministic installer engine with module‑based progress detection, replacing
                   filesystem‑scanning heuristics with phase‑aware, child‑specific module tracking for
                   reliable progress monitoring and accurate stall detection.'
    PowerShellVersion = '7.0'
    FunctionsToExport = @(
        'Update-VSCode',
        'Get-VSCodeVersions',
        'Switch-VSCodeVersion',
        'Invoke-VSCodeRollback',
        'Test-VSCodeSymlink',
        'Start-VSCodeSafeMode',
        'Get-VSCodeDashboard',
        'Invoke-InstallerWrapper',
        'Invoke-ZipFallback',
        'Get-VSCodeSymlinkInfo',
        'Get-VSCodeLastResult',
        'Set-VSCodeSafeMode',
        'Start-VSCodeRepair',
        'Set-VSCodeSafeInstallerMode',
        'Test-VSCodeInstall'
    )

    PrivateData = @{
        PSData = @{
            ProjectUri = 'https://github.com/Linktech-Engineering-LLC/VSCode-Updater'
            LicenseUri = 'https://github.com/Linktech-Engineering-LLC/VSCode-Updater/blob/main/LICENSE'
            IconUri = 'https://raw.githubusercontent.com/Linktech-Engineering-LLC/VSCode-Updater/main/icon.png'
            Tags = @('vscode' , 'update' , 'automation' , 'windows' , 'powershell' , 'devtools')
            ReleaseNotes = 'v3.0 introduces a new module‑based installer engine, replacing filesystem scanning with
                            deterministic phase tracking and improving reliability of progress and stall detection.'
        }
    }
}
