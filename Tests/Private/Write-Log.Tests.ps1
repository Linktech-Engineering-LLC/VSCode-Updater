<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-05
    Modified: 2026-07-05
    File: Write-VSCodeUpdaterLog.Tests.ps1
    Version: 1.0.0
    Description: Description goes here
#>

Describe "Write-VSCodeUpdaterLog" {

    BeforeAll {
        . "$PSScriptRoot/../../Private/Write-VSCodeUpdaterLog.ps1"
    }

    It "creates the log directory if missing" {
        Mock Test-Path { return $false }
        Mock New-Item {}
        Mock Add-Content {}
        Mock Write-Host {}

        Write-VSCodeUpdaterLog "Hello"

        Should -Invoke New-Item -Times 1
    }

    It "writes a timestamped message" {
        Mock Test-Path { return $true }
        Mock Add-Content {}
        Mock Write-Host {}

        Write-VSCodeUpdaterLog "Test message"

        Should -Invoke Add-Content -Times 1
    }
}
