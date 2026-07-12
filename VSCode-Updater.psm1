<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-04-16
    Modified: 2026-07-05
    File: VSCode-Updater.psm1
    Version: 2.2.0
    Description: Module root for VSCode-Updater. Loads public functions, wires private helpers,
                 and exposes deterministic update, rollback, symlink diagnostics, and safe-mode operations.
#>

# =====================================================================
#  Load Public + Private Functions
# =====================================================================

Get-ChildItem -Path "$PSScriptRoot/Public" -Filter *.ps1 -ErrorAction SilentlyContinue |
    Sort-Object Name |
    ForEach-Object { . $_.FullName }

Get-ChildItem -Path "$PSScriptRoot/Private" -Filter *.ps1 -ErrorAction SilentlyContinue |
    Sort-Object Name |
    ForEach-Object { . $_.FullName }

# =====================================================================
#  Module-Level Constants
# =====================================================================

Set-Variable -Name VSU_MaxRetries     -Value 5   -Scope Script -Option ReadOnly
Set-Variable -Name VSU_DetectTimeout  -Value 10  -Scope Script -Option ReadOnly
Set-Variable -Name VSU_DefaultIdle    -Value 600 -Scope Script -Option ReadOnly
Set-Variable -Name VSU_SafeInstallerMode -Value $true -Scope Script -Option ReadOnly

# Load module version from manifest
$script:ModuleVersion = (Import-PowerShellDataFile "$PSScriptRoot\VSCode-Updater.psd1").ModuleVersion

Write-Log "[INIT] VSCode-Updater module loaded — version $script:ModuleVersion"


# =====================================================================
#  Update-VSCode (Public Entry Point)
# =====================================================================

function Update-VSCode {
    [CmdletBinding()]
    param(
        [switch]$SkipUpdate,
        [switch]$SkipDownload,
        [switch]$ForceDownload,
        [int]$RetryCount = 3,
        [int]$IdleTimeout = $script:VSU_DefaultIdle
    )

    if ($script:SafeMode) {
        _out "SAFE MODE — Update skipped." "Yellow"
        return
    }

    # Metadata
    $scriptName    = "Update-VSCode"
    $scriptVersion = $script:ModuleVersion

    $codeExe    = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
    $codeRoot   = Split-Path $codeExe -Parent
	$InstallRoot = "$env:LOCALAPPDATA\Programs"
    $cacheDir   = "$PSScriptRoot/../Cache"
    $cachedInstaller = Join-Path $cacheDir "VSCodeSetup.exe"
    $installerUrl    = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"

    $script:LastUpdateResult   = $null
    $script:LastFallbackReason = $null

    if (-not (Test-Path $cacheDir)) {
        New-Item -ItemType Directory -Force -Path $cacheDir | Out-Null
    }

    Write-Log "==============================================================================="
    Write-Log "  $scriptName started — Version $scriptVersion"
    Write-Log "  Host: $env:COMPUTERNAME"
    Write-Log "  User: $env:USERNAME"
    Write-Log "  RetryCount=$RetryCount  IdleTimeout=$IdleTimeout"
    Write-Log "==============================================================================="

    # =====================================================================
    #  Guard: VS Code must not be running
    # =====================================================================

    $running = Get-Process -Name "Code", "Code - Insiders" -ErrorAction SilentlyContinue

    if ($running) {
        _out "VS Code is currently running."
        _out "Updating requires closing VS Code."

        $choice = Read-Host "Close VS Code and continue? (Y/N)"

        if ($choice -notin @('Y','y')) {
            Write-Log -Level Warning -Message "User aborted update because VS Code was running."
            $script:LastUpdateResult   = "Failed"
            $script:LastFallbackReason = "User aborted because VS Code was running"
            return 30
        }

        Write-Log -Level Info -Message "Closing VS Code to continue update."
        $running | Stop-Process -Force
    }

    # =====================================================================
    #  Pre‑Cleanup
    # =====================================================================

    Invoke-VSUPreCleanup -InstallRoot $InstallRoot

    # =====================================================================
    #  Skip Mode
    # =====================================================================

    if ($SkipUpdate) {
        Write-Log "[SKIP] SkipUpdate switch present — skipping update."
        $script:LastUpdateResult   = "Skipped"
        $script:LastFallbackReason = $null
        Write-Log "----- $scriptName ended (exit 20) -----"
        return 20
    }

    # =====================================================================
    #  Download + Cache Installer
    # =====================================================================

    $Mode = if ($SkipDownload) { "Skip" }
            elseif ($ForceDownload) { "Force" }
            else { "Normal" }

    _out "Installer URL: '$installerUrl'"
    _out "Length: $($installerUrl.Length)"

    Get-Installer -Url $installerUrl -CachePath $cachedInstaller -DownloadMode $Mode

    if (-not (Test-Path $cachedInstaller)) {
        Write-Log "[ERROR] Cached installer missing after update"
        $script:LastUpdateResult   = "Failed"
        $script:LastFallbackReason = "Cached installer missing"
        Write-Log "----- $scriptName ended (exit 12) -----"
        return 12
    }

    # Diagnostics
    $size = (Get-Item $cachedInstaller).Length
    if ($size -lt 5MB) {
        Write-Log "[DETECT] Cached installer appears corrupted or incomplete (size: $size bytes)"
    }

    $installerItem = Get-Item $cachedInstaller
    $age = (Get-Date) - $installerItem.LastWriteTime
    if ($age.TotalDays -gt 7) {
        Write-Log "[DETECT] Cached installer is stale (age: $([math]::Round($age.TotalDays,2)) days)"
    }

	# =====================================================================
	#  Retry Loop
	# =====================================================================

	# DO NOT run aggressive cleanup before PID exists
	# (leave Clear-InnoSetupWorkers commented out here)

	if ($RetryCount -gt $script:VSU_MaxRetries) {
		Write-Log "[WARN] RetryCount ($RetryCount) exceeds maximum allowed ($script:VSU_MaxRetries). Clamping."
		$RetryCount = $script:VSU_MaxRetries
	}

	$attempt     = 0
	$maxAttempts = $RetryCount + 1

	while ($attempt -lt $maxAttempts) {
		$attempt++
		Write-Log "[ATTEMPT] Installer attempt $attempt of $maxAttempts"

		try {
			# Launch installer FIRST
			$p = Start-InstallerDetached -Path $cachedInstaller
			$parentPID = $p.Id

			# Set installer PID BEFORE any cleanup
			$script:CurrentInstallerPID = $parentPID
			Write-Log "[DETECT] Parent PID: $parentPID"

			# NOW it is safe to run aggressive cleanup
			#Clear-VSCodeHelpers | Out-Null
			#Clear-InnoSetupWorkers | Out-Null

			# Child detection
			$child = $null
			$elapsed = 0

			while (-not $child -and $elapsed -lt $script:VSU_DetectTimeout) {
				Start-Sleep -Milliseconds 500
				$elapsed += 1

                # Robust InnoSetup worker detection
                $child = Get-Process -ErrorAction SilentlyContinue |
                    Where-Object {
                        $_.Id -ne $parentPID -and (
                            $_.Name -match '^is-[A-Za-z0-9]+' -or
                            $_.Name -match 'tmp$' -or
                            $_.Name -match 'tmp\.exe$' -or
                            ($_.Path -and $_.Path -match 'is-[A-Za-z0-9]+\.tmp') -or
                            ($_.CommandLine -and $_.CommandLine -match 'is-[A-Za-z0-9]+\.tmp')
                        )
                    } |
                    Sort-Object StartTime |
                    Select-Object -Last 1
			}

			if ($child) {
				$childPID = $child.Id
				Write-Log "[DETECT] Child worker PID: $childPID (found after ${elapsed}s)"
			} else {
				Write-Log "[DETECT] No child worker detected — treating as installer failure"

				# PID-aware cleanup (safe)
				Clear-VSCodeHelpers | Out-Null
				Clear-InnoSetupWorkers | Out-Null
				continue
			}

			# Watchdog
			$result = Watchdog-MonitorInstaller -ChildProcess $child -ParentPID $parentPID -IdleTimeout $IdleTimeout

			switch ($result) {
				"Success" {
					Write-Log "[WATCHDOG] Installer exited normally"
					break
				}
				"FS-Stalled" {
					Write-Log "[WATCHDOG] Filesystem stall detected"
					break
				}
				"Idle-Stalled" {
					Write-Log "[WATCHDOG] CPU/Disk idle stall"
					break
				}
				"Active-Stalled" {
					Write-Log "[WATCHDOG] CPU/Disk active stall"
					break
				}
				default {
					Write-Log "[WATCHDOG] Unexpected watchdog state: $result"
					break
				}
			}
		}
		catch {
			Write-Log "[ERROR] Installer start failure: $($_.Exception.Message)"
			if ($attempt -ge $maxAttempts) {
				Write-Log "----- $scriptName ended (exit 13) (Start Failure) -----"
				$script:LastUpdateResult   = "Failed"
				$script:LastFallbackReason = "Installer start failure"
				return 13
			}
			Write-Log "[RETRY] Retrying due to start failure"
			continue
		}

		# PID-aware cleanup
		Clear-VSCodeHelpers | Out-Null
		Clear-InnoSetupWorkers | Out-Null

		if ($result -eq "Success") {
			Write-Log "[SUCCESS] Installer completed successfully on attempt $attempt"
			$script:LastUpdateResult   = "Success"
			$script:LastFallbackReason = $null
			break
		}
		else {
			Write-Log "[STALL] Installer stalled on attempt $attempt"

			if ($result -like "*Stall*") {
				Write-Log "[STALL] Detected stall state '$result' — invoking ZIP fallback"
				return Invoke-ZipFallback -Reason $result
			}

			if ($attempt -ge $maxAttempts) {
				Write-Log "[FAIL] Installer stalled after $attempt attempts — invoking ZIP fallback"
				return Invoke-ZipFallback -Reason "Installer stalled after $attempt attempts"
			}

			Write-Log "[RETRY] Cleaning processes and artifacts before retry"
			Clear-VSCodeHelpers | Out-Null
			Clear-InnoSetupWorkers | Out-Null
			continue
		}
	}

    # =====================================================================
    #  Post‑Install Health Check
    # =====================================================================

    Write-Log "[CHECK] Running post-install health validation"

    # ---------------------------------------------------------
    # 1. Code.exe must exist
    # ---------------------------------------------------------

    if (-not (Test-Path $codeExe)) {
        Write-Log "[CHECK] Code.exe missing — triggering ZIP fallback"
        return Invoke-ZipFallback -Reason "Missing Code.exe"
    }

    # ---------------------------------------------------------
    # 2. Code.exe must launch and stay running briefly
    # ---------------------------------------------------------

    try {
        $proc = Start-Process $codeExe -PassThru -ErrorAction Stop

        $elapsed  = 0
        $maxWait  = 5
        $interval = 250  # ms

        while ($elapsed -lt $maxWait) {
            Start-Sleep -Milliseconds $interval
            $elapsed += ($interval / 1000)

            if ($proc.HasExited) {
                Write-Log "[CHECK] VS Code exited immediately — triggering ZIP fallback"
                return Invoke-ZipFallback -Reason "Launch failure"
            }
        }

        # Kill the test process
        $proc | Stop-Process -Force
    }
    catch {
        Write-Log "[CHECK] Exception launching VS Code: $($_.Exception.Message)"
        return Invoke-ZipFallback -Reason "Launch exception"
    }

    # ---------------------------------------------------------
    # 3. Debris check (shared patterns)
    # ---------------------------------------------------------

    $debrisPatterns = @(
        "update.exe",
        "*.tmp",
        "*.partial",
        "is-*.tmp",
        "is-*.bin",
        "innosetup.tmp",
        "new_*",
        "tmp_*",
        "partial_*"
    )

    foreach ($pattern in $debrisPatterns) {
        $items = Get-ChildItem -Path $codeRoot -Filter $pattern -ErrorAction SilentlyContinue
        if ($items) {
            Write-Log "[CHECK] Detected leftover update debris ($pattern) — triggering ZIP fallback"
            return Invoke-ZipFallback -Reason "Debris detected"
        }
    }

    # ---------------------------------------------------------
    # 4. Mark installer success for rotation/symlink stage
    # ---------------------------------------------------------

    Write-Log "[CHECK] Health check passed — installer appears successful"
    $script:InstallerSucceeded = $true

# =====================================================================
#  Finalization
# =====================================================================

Write-Log "[FINAL] Waiting for cleanup to settle"
Start-Sleep -Seconds 5

# ---------------------------------------------------------
# 1. If full installer succeeded → rename + symlink
# ---------------------------------------------------------

if ($script:InstallerSucceeded) {

    Write-Log "[FINAL] Full installer succeeded — performing rotation"

    # Generate timestamped folder name
    $timestamp = (Get-Date).ToString("yyyyMMddHHmmss")
    $newFolder = Join-Path $InstallRoot "VSCode-$timestamp"

    # Full installer writes to fixed folder name
    $fullInstallFolder = Join-Path $InstallRoot "Microsoft VS Code"

    if (Test-Path $fullInstallFolder) {
        Write-Log "[FINAL] Renaming '$fullInstallFolder' → '$newFolder'"
        Rename-Item -Path $fullInstallFolder -NewName "VSCode-$timestamp"
    }
    else {
        Write-Log "[FINAL] Expected full-install folder missing — invoking ZIP fallback"
        return Invoke-ZipFallback -Reason "Missing full-install folder during finalization"
    }

    # Create symlink
    $symlinkPath = Join-Path $InstallRoot "VSCode"

    if (Test-Path $symlinkPath) {
        Write-Log "[FINAL] Removing old symlink"
        Remove-Item $symlinkPath -Force -ErrorAction SilentlyContinue
    }

    Write-Log "[FINAL] Creating symlink VSCode → VSCode-$timestamp"
    New-Item -ItemType Junction -Path $symlinkPath -Target $newFolder | Out-Null

    Update-VSCodeVersions -Keep 3
}

    # ---------------------------------------------------------
    # 2. Final result logging
    # ---------------------------------------------------------

    if ($attempt -lt $maxAttempts){
        Write-Log "[FINAL] Update-VSCode completed successfully after $attempt attempts"
        $script:LastUpdateResult   = "Success"
        $script:LastFallbackReason = $null
    } else {
        Write-Log "[FAIL] Errors encountered Updating VSCode"
        $script:LastUpdateResult   = "Failed"
        $script:LastFallbackReason = "Unknown finalization failure"
    }

    Write-Log "==============================================================================="

    return $null
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
