<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-17
    Modified: 2026-07-17
    File: Private/Invoke-InstallerWrapper.ps1
    Version: 1.0.0
    Description: Orchestrates VS Code installer launch, child detection, watchdog monitoring,
                 finalization window, health check, rotation, and fallback handling.
#>
function Invoke-InstallerWrapper {
    [OutputType([WatchdogExitCode])]
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [string]$InstallerPath,

        [Parameter(Mandatory = $true)]
        [int]$IdleTimeout
    )

    try {
        $parent = Invoke-InstallerDetached -Path $InstallerPath
        $parentPID = $parent.Id

        Write-VSCodeUpdaterLog "[WRAPPER] Parent PID: $parentPID"

        $child = $null
        for ($i = 1; $i -le 10; $i++) {
            $child = Get-InnoChildProcess -ParentPID $parentPID
            if ($child) { break }
            Start-Sleep -Milliseconds 300
        }

        if (-not $child) {
            Write-VSCodeUpdaterLog "[WRAPPER] No child worker detected"
            return [WatchdogExitCode]::InstallerFailed
        }

        $childPID = $child.ProcessId
        Write-VSCodeUpdaterLog "[WRAPPER] Child PID: $childPID"

        # ---------------------------------------------------------------------
        # Stabilization delay: allow InnoSetup worker to fully initialize
        # ---------------------------------------------------------------------
        Write-VSCodeUpdaterLog "[WRAPPER] Stabilizing child process before watchdog"
        Start-Sleep -Milliseconds 1500

        $result = Invoke-InstallerWatchdog -ChildProcess $child -ParentPID $parentPID -IdleTimeout $IdleTimeout

        switch ($result) {
            "Success" { return [WatchdogExitCode]::Success }
            "FS-Stalled" { return [WatchdogExitCode]::FSStalled }
            "Idle-Stalled" { return [WatchdogExitCode]::IdleStalled }
            "Active-Stalled" { return [WatchdogExitCode]::ActiveStalled }
            default { return [WatchdogExitCode]::InstallerFailed }
        }
    }
    catch [InstallerNotFoundException] {
        return [WatchdogExitCode]::InstallerNotFound
    }
    catch [InvalidInstallerExtensionException] {
        return [WatchdogExitCode]::InvalidInstallerExtension
    }
    catch [InstallerTooSmallException] {
        return [WatchdogExitCode]::InstallerTooSmall
    }
    catch [VSCodeRunningUserDeclinedException] {
        return [WatchdogExitCode]::VSCodeRunningUserDeclined
    }
    catch [ExistingInstallerDetectedException] {
        return [WatchdogExitCode]::ExistingInstallerDetected
    }
    catch [InstallerLaunchFailedException] {
        return [WatchdogExitCode]::InstallerLaunchFailed
    }
    catch {
        Write-VSCodeUpdaterLog "[WRAPPER] Exception: $($_.Exception.Message)"
        return [WatchdogExitCode]::InstallerException
    }
}
