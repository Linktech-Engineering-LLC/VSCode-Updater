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

    Write-Log "[SAFE MODE] Diagnostic mode started"
    _out "=== UPDATER SAFE MODE STARTED ===" "Yellow"

    # Hardened diagnostics
    $info     = Get-VSCodeSymlinkInfo
    $versions = Get-VSCodeVersions
    $procs    = Get-Process -Name "Code" -ErrorAction SilentlyContinue

    _out "Scanning VS Code environment..." "LightGray"

    # Versions
    _out "Available Versions:" "LightBlue"
    foreach ($v in $versions) {
        $valid = if ($v.IsValid) { "Valid" } else { "INVALID" }
        _out (" - {0} ({1})" -f $v.VersionName, $valid)
    }

    # Symlink info
    _out "Symlink Target: $($info.TargetPath)"
    _out "Symlink Valid:  $($info.IsValid)"
    _out "Active Version: $($info.ActiveVersion)" "LightGreen"

    if (-not $info.IsValid) {
        _out "WARNING: Symlink is broken or invalid." "Red"
    }

    # Process info
    if ($procs) {
        foreach ($p in $procs) {
            _out "VS Code Running (PID $($p.Id))" "LightGreen"
            _out ("Memory: {0:N2} MB" -f ($p.WorkingSet64 / 1MB)) "LightGray"
            _out ("CPU Time: {0:N2} sec" -f $p.CPU) "LightGray"
        }
    }
    else {
        _out "VS Code is not running." "Red"
    }

    _out "=== UPDATER SAFE MODE COMPLETE ===" "Yellow"
    Write-Log "[SAFE MODE] Diagnostic mode complete"
}
