<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-04-16
    Modified: 2026-07-17
    File: Private/Invoke-InstallerWatchdog.ps1
    Version: 2.2.0
    Description: Monitors the VS Code installer using deterministic module‑based progress detection.
                 Tracks child‑process module loads, unloads, and phase transitions to identify real
                 installer activity, replacing filesystem‑scanning heuristics with noise‑free,
                 phase‑aware stall detection. Terminates the installer only when module state and
                 CPU/disk activity indicate a true stall.
#>
# PSScriptAnalyzer SuppressMessage = PSUseApprovedVerbs "Intentional verb"
# PSScriptAnalyzer SuppressMessage = PSUseConsistentWhitespace
# PSScriptAnalyzer SuppressMessage = PSUseConsistentIndentation
function Invoke-InstallerWatchdog {
    [OutputType([Int32])]
    param(
        $ChildProcess,
        [int]$ParentPID,
        [int]$IdleTimeout
    )

    # Validate parent
    if ($ParentPID -eq 0 -or -not (Get-Process -Id $ParentPID -ErrorAction SilentlyContinue)) {
        Write-VSCodeUpdaterLog "[WATCHDOG] Invalid parent PID ($ParentPID) — aborting watchdog"
        return [WatchdogExitCode]::Unknown
    }

    # Safe mode bypass
    if ($script:SafeMode) {
        Write-VSCodeUpdaterLog "[WATCHDOG] SAFE MODE — watchdog disabled"
        return [WatchdogExitCode]::Success
    }

    # Module tracking (v3.0)
    $previousModules = @()
    $moduleInitialized = $false
    $currentPhase = "Bootstrap"

    # Final install directory detection
    $finalInstallRoot = (Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code")

    # Idle timer
    $idleSeconds = 0.0
    $lastLoopTime = Get-Date

    Write-VSCodeUpdaterLog "[WATCHDOG] Monitoring child PID $($ChildProcess.Id), parent PID $ParentPID"

    # Grace period
    Start-Sleep -Seconds 3
    $idleSeconds = 0.0

    while ($true) {

        # Loop delta
        $now   = Get-Date
        $delta = ($now - $lastLoopTime).TotalSeconds
        if ($delta -lt 0) { $delta = 0 }
        $lastLoopTime = $now

        $idleSeconds += $delta

        # Refresh child
        $child = Get-Process -Id $ChildProcess.Id -ErrorAction SilentlyContinue

        if (-not $child) {
            Write-VSCodeUpdaterLog "[WATCHDOG] Child exited — installer completed"
            return [WatchdogExitCode]::Success
        }

        #
        # MODULE-BASED PROGRESS DETECTION (v3.0)
        #
        try {
            # Normalize module paths
            $currentModules = $child.Modules.FileName |
                ForEach-Object { $_.ToLowerInvariant() }

            if (-not $moduleInitialized) {
                Write-VSCodeUpdaterLog "[WATCHDOG] Module tracking initialized ($($currentModules.Count) modules)"
                $previousModules = $currentModules
                $moduleInitialized = $true
            }
            else {
                # Single delta calculation
                $moduleDelta = Compare-Object $previousModules $currentModules

                if ($moduleDelta) {
                    Write-VSCodeUpdaterLog "[WATCHDOG] Module change detected"
                    $previousModules = $currentModules
                    $idleSeconds = 0.0

                    #
                    # PHASE DETECTION (v3.0)
                    #
                    $newPhase = $currentPhase

                    if ($currentModules -match '\\nsm.*\.tmp\\') {
                        $newPhase = "Extraction"
                    }
                    elseif ($currentModules -match 'chrome_elf\.dll' -or
                            $currentModules -match 'node\.dll') {
                        $newPhase = "Payload"
                    }
                    elseif ($currentModules -match '\microsoft vs code\\') {
                        $newPhase = "Finalization"
                    }

                    if ($newPhase -ne $currentPhase) {
                        $currentPhase = $newPhase
                        Write-VSCodeUpdaterLog "[WATCHDOG] Phase: $currentPhase"
                    }
                }
            }
        }
        catch {
            Write-VSCodeUpdaterLog "[WATCHDOG] Module polling exception: $($_.Exception.Message)"
        }

        #
        # FINALIZATION SUCCESS DETECTION (v3.0)
        #
        $finalModulesLoaded = $currentModules |
            Where-Object { $_ -like "$($finalInstallRoot.ToLowerInvariant())\*" }

        if ($finalModulesLoaded.Count -gt 0 -and $currentPhase -eq "Finalization") {
            Write-VSCodeUpdaterLog "[WATCHDOG] Final modules loaded — installer completed"
            return [WatchdogExitCode]::Success
        }

        #
        # PURE MODULE-ONLY STALL DETECTION (v3.0)
        #
        $moduleDelta = Compare-Object $previousModules $currentModules

        if (-not $moduleDelta) {
            if ($idleSeconds -ge $IdleTimeout) {
                Write-VSCodeUpdaterLog "[WATCHDOG] Deterministic stall — no module changes for $IdleTimeout seconds"
                Stop-Process -Id $ChildProcess.Id -Force -ErrorAction SilentlyContinue
                Stop-Process -Id $ParentPID     -Force -ErrorAction SilentlyContinue
                return [WatchdogExitCode]::IdleStalled
            }
        }
        else {
            $idleSeconds = 0.0
        }

        Start-Sleep -Seconds 2
    }
}
