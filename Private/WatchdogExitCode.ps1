<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-17
    Modified: 2026-07-17
    File: Private/WatchdogExitCodes.ps1
    Version: 1.0.0
    Description: Description goes here
#>
enum WatchdogExitCode {
    Success = 0

    # Installer Start Failures
    InstallerNotFound = 80
    InvalidInstallExtension = 81
    InstallerTooSmall = 82
    InstallerLaunchFailed = 83
    VSCodeRunningUserDeclined = 84

    # Installer stall states (existing)
    IdleStalled = 91
    ActiveStalled = 92
    FSStalled = 93

    # Installer failure states
    InstallerFailed = 100
    InstallerException = 101

    # Health check failures
    MissingCodeExe = 110
    LaunchFailed = 111
    LaunchException = 112
    HealthCheckFailed = 113
    ServicingBlocked = 114

    # Fallback failures
    FallbackFailed = 120

    # Updater-level failures
    UpdateException = 130

    # Catch-all
    Unknown = 199
}
