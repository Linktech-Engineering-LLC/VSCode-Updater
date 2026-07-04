<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-06-14
    Modified: 2026-06-14
    File: Start-VSCodeSafeMode.ps1
    Version: 1.0.0
    Description: Description goes here
#>

function Start-VSCodeSafeMode {
    [CmdletBinding()]
    param()

    _out "=== UPDATER SAFE MODE STARTED ===" "Yellow"

    # Read-only diagnostics
    $info     = Get-VSCodeSymlinkInfo
    $versions = Get-VSCodeVersions
    $proc = Get-Process -Name "Code" -ErrorAction SilentlyContinue | Select-Object -First 1

    _out "Scanning VS Code environment..." "LightGray"

    # Versions
    _out "Available Versions:" "LightBlue"
    foreach ($v in $versions) {
        _out " - $v"
    }

    # Symlink info
    _out "Symlink Target: $($info.TargetPath)"
    _out "Symlink Valid:  $($info.IsValid)"
    _out "Active Version: $($info.ActiveVersion)" "LightGreen"

    # Process info
    if ($proc) {
        _out "VS Code Running (PID $($proc.Id))" "LightGreen"
        _out ("Memory: {0:N2} MB" -f ($proc.WorkingSet64 / 1MB)) "LightGray"
        _out ("CPU Time: {0:N2} sec" -f $proc.CPU) "LightGray"
    }
    else {
        _out "VS Code is not running." "Red"
    }

    _out "=== UPDATER SAFE MODE COMPLETE ===" "Yellow"
}
