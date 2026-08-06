<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-04-16
    Modified: 2026-07-05
    File: VSCode-Updater.psm1
    Version: 3.0.0
    Description: Module root for VSCode-Updater. Loads public functions, wires private helpers,
                 and exposes deterministic update, rollback, symlink diagnostics, and safe-mode operations.
#>

# =====================================================================
#  Load Public + Private Functions
# =====================================================================
# Load enum FIRST
. "$PSScriptRoot/Private/WatchdogExitCode.ps1"
. "$PSScriptRoot/Private/InstallerExceptions.ps1"

# Load all other private files
Get-ChildItem -Path "$PSScriptRoot/Private" -Filter *.ps1 |
    Where-Object { $_.Name -ne 'WatchdogExitCode.ps1' } |
    Sort-Object Name |
    ForEach-Object { . $_.FullName }

# Load public files LAST
Get-ChildItem -Path "$PSScriptRoot/Public" -Filter *.ps1 |
    Sort-Object Name |
    ForEach-Object { . $_.FullName }


# =====================================================================
#  Module-Level Constants
# =====================================================================

Set-Variable -Name VSU_MaxRetries     -Value 5   -Scope Script -Option ReadOnly
Set-Variable -Name VSU_DetectTimeout  -Value 10  -Scope Script -Option ReadOnly
Set-Variable -Name VSU_DefaultIdle    -Value 900 -Scope Script -Option ReadOnly
Set-Variable -Name VSU_SafeInstallerMode -Value $true -Scope Script -Option ReadOnly

# Load module version from manifest
$script:ModuleVersion = (Import-PowerShellDataFile "$PSScriptRoot\VSCode-Updater.psd1").ModuleVersion

Write-VSCodeUpdaterLog "[INIT] VSCode-Updater module loaded — version $script:ModuleVersion"


# =====================================================================
#  Update-VSCode (Public Entry Point)
# =====================================================================

function Update-VSCode {
    [OutputType([Int32])]
    [CmdletBinding(SupportsShouldProcess = $true)]
    param()

    $null = Write-VSCodeUpdaterLog "[UPDATE] Starting VS Code update"
    Clear-SetupBootstrapper | Out-Null
    Clear-VSCodeHelpers | Out-Null
    Clear-InnoSetupWorkers | Out-Null

    if (-not $PSCmdlet.ShouldProcess("VS Code installation", "Update")) {
        $null = Write-VSCodeUpdaterLog "[UPDATE] ShouldProcess declined"
        return [WatchdogExitCode]::UpdateException
    }

    $finalResult = $null
    $installerUrl = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"
    $cacheDir = Join-Path $PSScriptRoot "..\Cache"
    $cachedInstaller = Join-Path $cacheDir "VSCodeUserSetup.exe"

    $cachedInstaller = Normalize-Scalar(Get-Installer -Url $installerUrl -CachePath $cachedInstaller -DownloadMode "Normal")

    if (-not $cachedInstaller) {
        $null = Write-VSCodeUpdaterLog "[UPDATE] Installer acquisition failed — invoking ZIP fallback"
        Invoke-ZipFallback -Reason [WatchdogExitCode]::InstallerFailed | Out-Null
        return [WatchdogExitCode]::InstallerFailed
    }

    try {
        # =====================================================================
        #  Installer Retry Loop
        # =====================================================================

        $maxAttempts = 3
        $attempt = 0
        $installerFailed = $false
        $fallbackReason = $null

        while ($attempt -lt $maxAttempts) {
            $attempt++
            $null = Write-VSCodeUpdaterLog "[ATTEMPT] Installer attempt $attempt of $maxAttempts"

            $result = Invoke-InstallerWrapper -InstallerPath $cachedInstaller -IdleTimeout $script:VSU_DefaultIdle

            Clear-VSCodeHelpers | Out-Null
            Clear-InnoSetupWorkers | Out-Null

            if ($result -eq [WatchdogExitCode]::Success) {
                $null = Write-VSCodeUpdaterLog "[SUCCESS] Installer completed successfully on attempt $attempt"
                break
            }

            if ($result -in @(
                    [WatchdogExitCode]::IdleStalled,
                    [WatchdogExitCode]::ActiveStalled,
                    [WatchdogExitCode]::FSStalled
                )) {
                $null = Write-VSCodeUpdaterLog "[STALL] Installer stalled on attempt $attempt"
                $installerFailed = $true
                $fallbackReason = $result
                break
            }

            if ($attempt -ge $maxAttempts) {
                $null = Write-VSCodeUpdaterLog "[STALL] Installer stalled after $attempt attempts"
                $installerFailed = $true
                $fallbackReason = [WatchdogExitCode]::InstallerFailed
                break
            }

            $null = Write-VSCodeUpdaterLog "[RETRY] Cleaning processes and artifacts before retry"
            Clear-SetupBootstrapper | Out-Null
            Clear-VSCodeHelpers | Out-Null
            Clear-InnoSetupWorkers | Out-Null
        }

        # =====================================================================
        #  Installer Failure → ZIP Fallback
        # =====================================================================

        if ($installerFailed) {
            $null = Write-VSCodeUpdaterLog "[FALLBACK] Installer failed — invoking ZIP fallback"
            Invoke-ZipFallback -Reason $fallbackReason | Out-Null

            $null = Write-VSCodeUpdaterLog "[CHECK] Running post-fallback health validation"

            if (-not (Test-VSCodeInstall)) {
                $null = Write-VSCodeUpdaterLog "[CHECK] Fallback health check failed"
                $finalResult = [WatchdogExitCode]::FallbackFailed
            }
            else {
                $null = Write-VSCodeUpdaterLog "[CHECK] Fallback health check passed"
                $finalResult = [WatchdogExitCode]::Success
            }

            return $finalResult
        }

        # =====================================================================
        #  Post‑Installer Health Check
        # =====================================================================

        $null = Write-VSCodeUpdaterLog "[CHECK] Running post-install health validation"

        $codeExe = Find-UserVSCode
        if (-not $codeExe) {
            Write-VSCodeUpdaterLog "[CHECK] No user-space VS Code installation detected — aborting instead of ZIP fallback"
            return [WatchdogExitCode]::MissingCodeExe
        }

        if (-not (Test-Path $codeExe)) {
            $null = Write-VSCodeUpdaterLog "[CHECK] Code.exe missing — invoking ZIP fallback"
            Invoke-ZipFallback -Reason [WatchdogExitCode]::MissingCodeExe | Out-Null

            $null = Write-VSCodeUpdaterLog "[CHECK] Running post-fallback health validation"

            if (-not (Test-VSCodeInstall)) {
                $null = Write-VSCodeUpdaterLog "[CHECK] Fallback health check failed"
                $finalResult = [WatchdogExitCode]::MissingCodeExe
            }
            else {
                $null = Write-VSCodeUpdaterLog "[CHECK] Fallback health check passed"
                $finalResult = [WatchdogExitCode]::Success
            }

            return $finalResult
        }

        try {
            $proc = Start-Process $codeExe -PassThru -ErrorAction Stop

            $elapsed = 0
            $maxWait = 5
            $interval = 250

            while ($elapsed -lt $maxWait) {
                Start-Sleep -Milliseconds $interval
                $elapsed += ($interval / 1000)

                if ($proc.HasExited) {
                    $null = Write-VSCodeUpdaterLog "[CHECK] VS Code exited immediately — invoking ZIP fallback"
                    Invoke-ZipFallback -Reason [WatchdogExitCode]::LaunchFailed | Out-Null

                    $null = Write-VSCodeUpdaterLog "[CHECK] Running post-fallback health validation"

                    if (-not (Test-VSCodeInstall)) {
                        $null = Write-VSCodeUpdaterLog "[CHECK] Fallback health check failed"
                        $finalResult = [WatchdogExitCode]::LaunchFailed
                    }
                    else {
                        $null = Write-VSCodeUpdaterLog "[CHECK] Fallback health check passed"
                        $finalResult = [WatchdogExitCode]::Success
                    }

                    return $finalResult
                }
            }

            $proc | Stop-Process -Force | Out-Null
        }
        catch {
            $null = Write-VSCodeUpdaterLog "[CHECK] Exception launching VS Code: $($_.Exception.Message)"
            Invoke-ZipFallback -Reason [WatchdogExitCode]::LaunchException | Out-Null

            $null = Write-VSCodeUpdaterLog "[CHECK] Running post-fallback health validation"

            if (-not (Test-VSCodeInstall)) {
                $null = Write-VSCodeUpdaterLog "[CHECK] Fallback health check failed"
                $finalResult = [WatchdogExitCode]::LaunchException
            }
            else {
                $null = Write-VSCodeUpdaterLog "[CHECK] Fallback health check passed"
                $finalResult = [WatchdogExitCode]::Success
            }

            return $finalResult
        }

        $null = Write-VSCodeUpdaterLog "[UPDATE] VS Code installation passed health check"
        $finalResult = [WatchdogExitCode]::Success
    }
    catch {
        $null = Write-VSCodeUpdaterLog "[UPDATE] Exception in Update-VSCode: $($_.Exception.Message)"
        Invoke-ZipFallback -Reason [WatchdogExitCode]::UpdateException | Out-Null

        $null = Write-VSCodeUpdaterLog "[CHECK] Running post-fallback health validation"

        if (-not (Test-VSCodeInstall)) {
            $null = Write-VSCodeUpdaterLog "[CHECK] Fallback health check failed"
            $finalResult = [WatchdogExitCode]::UpdateException
        }
        else {
            $null = Write-VSCodeUpdaterLog "[CHECK] Fallback health check passed"
            $finalResult = [WatchdogExitCode]::Success
        }
    }

    return $finalResult
}

# =====================================================================
#  Export Public Functions
# =====================================================================

Export-ModuleMember -Function @(
    'Update-VSCode'
    'Get-VSCodeVersions'
    'Switch-VSCodeVersion'
    'Invoke-VSCodeRollback'
    'Test-VSCodeSymlink'
    'Start-VSCodeSafeMode'
    'Get-VSCodeDashboard'
    'Invoke-ZipFallback'
    'Get-VSCodeSymlinkInfo'
    'Get-VSCodeLastResult'
    'Set-VSCodeSafeMode'
    'Start-VSCodeRepair'
    'Set-VSCodeSafeInstallerMode'
)
$PSDefaultParameterValues['*:OutVariable'] = $null
