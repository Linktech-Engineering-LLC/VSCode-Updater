function Update-VSCode {
	[CmdletBinding()]
	param(
		[switch]$SkipUpdate,
		[switch]$SkipDownload,
        [switch]$ForceDownload
		[int]$RetryCount = 3,
		[int]$IdleTimeout = 600
	)

    # =====================================================================
    #  Initialization + Metadata Banner
    # =====================================================================

    $scriptName    = "Update-VSCode"
    $scriptVersion = "2.0.0"

    $codeExe    = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"
    $codeRoot   = Split-Path $codeExe -Parent
    $cacheDir   = "$PSScriptRoot/../Cache"
    $cachedInstaller = Join-Path $cacheDir "VSCodeSetup.exe"
    $tempInstaller   = Join-Path $env:TEMP "VSCodeSetup.tmp"
    $installerUrl    = "https://update.code.visualstudio.com/latest/win32-x64-user/stable"

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
    #  Pre‑Cleanup
    # =====================================================================

    Cleanup-SetupBootstrapper
    Cleanup-VSCodeHelpers
    Cleanup-InnoSetupWorkers
    Start-Sleep -Seconds 2
    CleanCodePath
    Start-Sleep -Seconds 2

    # =====================================================================
    #  Skip Mode
    # =====================================================================

    if ($SkipUpdate) {
        Write-Log "[SKIP] SkipUpdate switch present — skipping update."
        Write-Log "----- $scriptName ended (exit 20) -----"
        return 20
    }

    # =====================================================================
    #  Download + Cache Installer
    # =====================================================================
	$Mode = if ($SkipDownload) {
		"Skip"
	}
	elseif ($ForceDownload) {
		"Force"
	}
	else {
		"Normal"
	}

	$installer = Get-Installer -Url $url -CachePath $cachedInstaller -DownloadMode $Mode
	

    if (-not (Test-Path $cachedInstaller)) {
        Write-Log "[ERROR] Cached installer missing after update"
        Write-Log "----- $scriptName ended (exit 12) -----"
        return 12
    }

    # =====================================================================
    #  Retry Loop
    # =====================================================================
	# NEW: Ensure no stale InnoSetup workers exist before launching installer
	Cleanup-InnoSetupWorkers
	Start-Sleep -Milliseconds 200

    $attempt     = 0
    $maxAttempts = $RetryCount + 1

    while ($attempt -lt $maxAttempts) {
        $attempt++
        Write-Log "[ATTEMPT] Installer attempt $attempt of $maxAttempts"

        try {
            # Launch installer
            $p = Start-InstallerDetached -Path $cachedInstaller
            $parentPID = $p.Id
            Write-Log "[DETECT] Parent PID: $parentPID"

			# Detect child worker using Win32_Process (reliable parent PID)
			$child = $null
			$detectTimeout = 10
			$elapsed = 0

			while (-not $child -and $elapsed -lt $detectTimeout) {
				Start-Sleep -Milliseconds 500
				$elapsed += 1

				$child = Get-CimInstance Win32_Process -Filter "ParentProcessId = $parentPID" -ErrorAction SilentlyContinue |
					Sort-Object CreationDate |
					Select-Object -Last 1
			}

			if ($child) {
				$childPID = $child.ProcessId
				Write-Log "[DETECT] Child worker PID: $childPID (found after ${elapsed}s)"
			} else {
				Write-Log "[DETECT] No child worker detected after ${detectTimeout}s — treating as installer failure"
				Cleanup-VSCodeHelpers
				Cleanup-InnoSetupWorkers
				continue
			}

            $childProcess = Get-Process -Id $childPID -ErrorAction SilentlyContinue
            $result = Watchdog-MonitorInstaller -ChildProcess $childProcess -ParentPID $parentPID -IdleTimeout $IdleTimeout
			switch ($result) {
				"Success" {
					Write-Log "[WATCHDOG] Installer exited normally"
					Write-Log "----- $scriptName ended (exit 0) -----"
					return 0
				}

				"FS-Stalled" {
					Write-Log "[WATCHDOG] Filesystem stall detected — no writes for $IdleTimeout seconds"
					Write-Log "----- $scriptName ended (exit 30) -----"
					return 30
				}

				"Idle-Stalled" {
					Write-Log "[WATCHDOG] CPU/Disk idle stall — no activity for $IdleTimeout seconds"
					Write-Log "----- $scriptName ended (exit 31) -----"
					return 31
				}

				"Active-Stalled" {
					Write-Log "[WATCHDOG] CPU/Disk active stall — metrics frozen for $IdleTimeout seconds"
					Write-Log "----- $scriptName ended (exit 32) -----"
					return 32
				}

				default {
					Write-Log "[WATCHDOG] Unexpected watchdog state: $result"
					Write-Log "----- $scriptName ended (exit 99) -----"
					return 99
				}
			}
        }
        catch {
            Write-Log "[ERROR] Installer start failure: $($_.Exception.Message)"
            if ($attempt -ge $maxAttempts) {
                Write-Log "----- $scriptName ended (exit 13) -----"
                return 13
            }
            Write-Log "[RETRY] Retrying due to start failure"
            continue
        }

        Cleanup-VSCodeHelpers
        Cleanup-InnoSetupWorkers

        if ($result -eq "Success") {
            Write-Log "[SUCCESS] Installer completed successfully on attempt $attempt"
            break
        }

        Write-Log "[STALL] Installer stalled on attempt $attempt"

        if ($attempt -ge $maxAttempts) {
            Write-Log "[FAIL] Installer stalled after $attempt attempts — aborting"
            Write-Log "----- $scriptName ended (exit 14) -----"
            return 14
        }

        Write-Log "[RETRY] Cleaning processes and artifacts before retry"

        Cleanup-VSCodeHelpers
        Cleanup-InnoSetupWorkers

        Get-Process Code, CodeHelper*, CodeSetup*, VSCodeSetup* -ErrorAction SilentlyContinue |
            Stop-Process -Force -ErrorAction SilentlyContinue
    }

    # =====================================================================
    #  Finalization
    # =====================================================================

    Write-Log "[FINAL] Waiting for cleanup to settle"
    Start-Sleep -Seconds 5
	
	if ($attempt -lt $maxAttempts){
		Write-Log "[FINAL] Update-VSCode completed successfully after $attempt attempts"
	} else {
		Write-Log "[FAIL] Errors encountered Updating VSCode"
	}
    Write-Log "==============================================================================="

    return 0
}
