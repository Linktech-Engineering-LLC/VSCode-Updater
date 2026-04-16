<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-04-16
    Modified: 2026-04-16
    File: Private/Get-Installer.ps1
    Version: 1.0.0
    Description: Retrieves the VS Code installer deterministically with support for Skip, Force, and Normal download modes, including hash validation and temp file cleanup.
#>
function Get-Installer {
    [CmdletBinding()]
    param(
        [string]$Url,
        [string]$CachePath,

        [ValidateSet("Skip","Force","Normal")]
        [string]$DownloadMode = "Normal"
    )

    Write-Log "[DOWNLOAD] Mode: $DownloadMode"

    switch ($DownloadMode) {

        "Skip" {
            Write-Log "[DOWNLOAD] Skip mode — using cached installer only"

            if (-not (Test-Path $CachePath)) {
                Write-Log "[ERROR] Skip mode used but no cached installer exists"
                return $null
            }

            return $CachePath
        }

        "Force" {
            Write-Log "[DOWNLOAD] Force mode — downloading fresh installer"

            try {
                Invoke-WebRequest -Uri $Url -OutFile $CachePath -UseBasicParsing -ErrorAction Stop
            }
            catch {
                Write-Log "[ERROR] Forced download failed: $($_.Exception.Message)"
                return $null
            }

            return $CachePath
        }

        "Normal" {
            Write-Log "[DOWNLOAD] Normal mode — checking cache"

            if (Test-Path $CachePath) {
                Write-Log "[DOWNLOAD] Cached installer exists — checking for update"

                $temp = Join-Path $env:TEMP "installer.tmp"

                try {
                    Invoke-WebRequest -Uri $Url -OutFile $temp -UseBasicParsing -ErrorAction Stop
                }
                catch {
                    Write-Log "[ERROR] Failed to download installer: $($_.Exception.Message)"
                    return $null
                }

                $cachedHash = Get-FileHashSafe -Path $CachePath
                $newHash    = Get-FileHashSafe -Path $temp

                if ($cachedHash -eq $newHash) {
                    Write-Log "[DOWNLOAD] Installer unchanged — keeping cached copy"
                    Remove-Item $temp -Force -ErrorAction SilentlyContinue
                    return $CachePath
                }

                Write-Log "[DOWNLOAD] Installer updated — replacing cached copy"
                Copy-Item $temp $CachePath -Force
                Remove-Item $temp -Force -ErrorAction SilentlyContinue
                return $CachePath
            }

            # No cache exists — download fresh
            Write-Log "[DOWNLOAD] No cached installer — downloading fresh copy"

            try {
                Invoke-WebRequest -Uri $Url -OutFile $CachePath -UseBasicParsing -ErrorAction Stop
            }
            catch {
                Write-Log "[ERROR] Failed to download installer: $($_.Exception.Message)"
                return $null
            }

            return $CachePath
        }
    }
}
