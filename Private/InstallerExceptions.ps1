<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-17
    Modified: 2026-07-17
    File: Private/InstallerExceptions.ps1
    Version: 1.0.0
    Description: Description goes here
#>
class InstallerException : System.Exception {
    InstallerException([string]$msg) : base($msg) {}
}

class InstallerNotFoundException : InstallerException {
    InstallerNotFoundException([string]$msg) : base($msg) {}
}

class InvalidInstallerExtensionException : InstallerException {
    InvalidInstallerExtensionException([string]$msg) : base($msg) {}
}

class InstallerTooSmallException : InstallerException {
    InstallerTooSmallException([string]$msg) : base($msg) {}
}

class VSCodeRunningUserDeclinedException : InstallerException {
    VSCodeRunningUserDeclinedException([string]$msg) : base($msg) {}
}

class ExistingInstallerDetectedException : InstallerException {
    ExistingInstallerDetectedException([string]$msg) : base($msg) {}
}

class InstallerLaunchFailedException : InstallerException {
    InstallerLaunchFailedException([string]$msg) : base($msg) {}
}
