<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-17
    Modified: 2026-07-17
    File: Private/Get-InnoChildProcess.ps1
    Version: 1.0.0
    Description: Description goes here
#>
function Get-InnoChildProcess {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [int]$ParentPID
    )

    Get-Process -ErrorAction SilentlyContinue |
        Where-Object {
            $_.Name -match '^is-[A-Za-z0-9]+' -or
            $_.Name -match 'tmp$' -or
            $_.Name -match 'tmp\.exe$' -or
            ($_.Path -and $_.Path -match 'is-[A-Za-z0-9]+\.tmp')
        } |
        Sort-Object StartTime |
        Select-Object -Last 1
}
