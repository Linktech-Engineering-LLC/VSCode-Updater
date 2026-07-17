<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-05
    Modified: 2026-07-05
    File: CleanCodePath.Tests.ps1
    Version: 1.0.0
    Description: Description goes here
#>

Describe "CleanCodePath" {
    BeforeAll {
        . "$PSScriptRoot/../../Private/CleanCodePath.ps1"
        . "$PSScriptRoot/../../Private/Write-VSCodeUpdaterLog.ps1"
    }

    It "skips when path does not exist" {
        Mock Test-Path { return $false }
        Mock Write-VSCodeUpdaterLog {}

        CleanCodePath -Path "C:\Fake"

        Assert-MockCalled Write-VSCodeUpdaterLog -Times 1 -ParameterFilter { $Message -match "Skipping" }
    }

    It "removes lock files" {
        Mock Test-Path { return $true }
        Mock Get-ChildItem { return @( [pscustomobject]@{ Name="is-123.tmp"; FullName="C:\Fake\is-123.tmp" } ) }
        Mock Remove-Item {}
        Mock Write-VSCodeUpdaterLog {}

        CleanCodePath -Path "C:\Fake"

        Assert-MockCalled Remove-Item -Times 1
    }
}
