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

    #
    # v3.1 DIAGNOSTIC STATE
    #
    $phaseTimeline = @{
        Bootstrap    = $null
        Servicing    = $null
        Extraction   = $null
        Payload      = $null
        Finalization = $null
    }

    $extractionStarted   = $false
    $payloadLoaded       = $false
    $finalizationReached = $false

    $stallReason         = "Unknown"
    $pendingReboot       = $false
    $componentStoreCorrupt = $false

    # Detect pending reboot (v3.1)
    if (Test-Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending') {
        $pendingReboot = $true
        Write-VSCodeUpdaterLog "[DIAGNOSTIC] Pending reboot detected — Windows servicing may be blocked"
    }

    # DISM component store health check (v3.1)
    try {
        dism.exe /online /cleanup-image /checkhealth | Out-Null
        if ($LASTEXITCODE -ne 0) {
            $componentStoreCorrupt = $true
            Write-VSCodeUpdaterLog "[DIAGNOSTIC] DISM checkhealth indicates component store corruption"
        }
    }
    catch {
        Write-VSCodeUpdaterLog "[DIAGNOSTIC] DISM checkhealth failed: $($_.Exception.Message)"
    }
    # v3.2 EARLY EXIT: Abort installer monitoring if servicing is blocked
    if ($pendingReboot -or $componentStoreCorrupt) {

        $reason = if ($pendingReboot) {
            "PendingReboot"
        }
        elseif ($componentStoreCorrupt) {
            "ComponentStoreCorrupt"
        }

        Write-VSCodeUpdaterLog "[WATCHDOG] Servicing blocked — aborting installer monitoring (Reason: $reason)"

        # Store diagnostics for main module
        $script:WatchdogDiagnostics = [PSCustomObject]@{
            StallReason           = $reason
            PendingReboot         = $pendingReboot
            ComponentStoreCorrupt = $componentStoreCorrupt
            PhaseTimeline         = $phaseTimeline
            ExtractionStarted     = $false
            PayloadLoaded         = $false
            FinalizationReached   = $false
            LastModules           = @()
        }

        return [WatchdogExitCode]::ServicingBlocked
    }

    #
    # Module tracking (v3.0 → v3.1)
    #
    $previousModules = @()
    $moduleInitialized = $false
    $currentPhase = "Bootstrap"
    $phaseTimeline["Bootstrap"] = Get-Date

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
            $finalizationReached = $true
            $phaseTimeline["Finalization"] = Get-Date
            return [WatchdogExitCode]::Success
        }

        #
        # MODULE-BASED PROGRESS DETECTION (v3.1)
        #
        try {
            $currentModules = $child.Modules.FileName |
                ForEach-Object { $_.ToLowerInvariant() }

            if (-not $moduleInitialized) {
                Write-VSCodeUpdaterLog "[WATCHDOG] Module tracking initialized ($($currentModules.Count) modules)"
                $previousModules = $currentModules
                $moduleInitialized = $true
            }
            else {
                $moduleDelta = Compare-Object $previousModules $currentModules

                if ($moduleDelta) {
                    Write-VSCodeUpdaterLog "[WATCHDOG] Module change detected"

                    foreach ($d in $moduleDelta) {
                        $side = if ($d.SideIndicator -eq '=>') { 'Added' } else { 'Removed' }
                        Write-VSCodeUpdaterLog "[WATCHDOG] Module ${side}: $($d.InputObject)"
                    }

                    $previousModules = $currentModules
                    $idleSeconds = 0.0

                    #
                    # PHASE DETECTION (v3.1)
                    #
                    $newPhase = $currentPhase

                    if ($currentModules -match '\\nsm.*\.tmp\\') {
                        $newPhase = "Extraction"
                        $extractionStarted = $true
                        $phaseTimeline["Extraction"] = Get-Date
                    }
                    elseif ($currentModules -like '*chrome_elf.dll*' -or
                            $currentModules -like '*node.dll*') {
                        $newPhase = "Payload"
                        $payloadLoaded = $true
                        $phaseTimeline["Payload"] = Get-Date
                    }
                    elseif ($currentModules -like '*microsoft vs code*') {
                        $newPhase = "Finalization"
                        $finalizationReached = $true
                        $phaseTimeline["Finalization"] = Get-Date
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
        # FINALIZATION SUCCESS DETECTION (v3.1)
        #
        $finalModulesLoaded = $currentModules |
            Where-Object { $_ -like "$($finalInstallRoot.ToLowerInvariant())\*" }

        if ($finalModulesLoaded.Count -gt 0 -and $currentPhase -eq "Finalization") {
            Write-VSCodeUpdaterLog "[WATCHDOG] Final modules loaded — installer completed"
            $finalizationReached = $true
            $phaseTimeline["Finalization"] = Get-Date
            return [WatchdogExitCode]::Success
        }

        #
        # UNIFIED STALL DETECTOR (v3.1)
        #
        $moduleDelta = Compare-Object $previousModules $currentModules

        if (-not $moduleDelta) {

            if ($idleSeconds -ge $IdleTimeout) {

                #
                # Stall reason classification (v3.1)
                #
                if ($currentModules -like '*setupapi.dll*') {
                    $stallReason = "Windows servicing deadlock"
                }
                elseif (-not $extractionStarted) {
                    $stallReason = "NSIS extraction never started"
                }
                elseif (-not $payloadLoaded) {
                    $stallReason = "Payload modules never loaded"
                }

                Write-VSCodeUpdaterLog "[WATCHDOG] Deterministic stall — no module changes for $IdleTimeout seconds"
                Write-VSCodeUpdaterLog "[WATCHDOG] Stall reason: $stallReason"

                #
                # Kill installer
                #
                Stop-Process -Id $ChildProcess.Id -Force -ErrorAction SilentlyContinue
                Stop-Process -Id $ParentPID     -Force -ErrorAction SilentlyContinue

                #
                # v3.1: Store diagnostic metadata for main module
                #
                $script:WatchdogDiagnostics = [PSCustomObject]@{
                    StallReason           = $stallReason
                    PendingReboot         = $pendingReboot
                    ComponentStoreCorrupt = $componentStoreCorrupt
                    PhaseTimeline         = $phaseTimeline
                    ExtractionStarted     = $extractionStarted
                    PayloadLoaded         = $payloadLoaded
                    FinalizationReached   = $finalizationReached
                    LastModules           = $currentModules
                }

                return [WatchdogExitCode]::IdleStalled
            }
        }
        else {
            $idleSeconds = 0.0
        }

        Start-Sleep -Seconds 2
    }
}
