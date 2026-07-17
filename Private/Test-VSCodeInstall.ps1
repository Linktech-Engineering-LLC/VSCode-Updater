<#
    SPDX-License-Identifier: MIT
    Copyright (c) 2026 Leon McClatchey, Linktech Engineering LLC

    Package: VSCode-Updater
    Author: Leon McClatchey
    Company: Linktech Engineering LLC
    Created: 2026-07-17
    Modified: 2026-07-17
    File: Private/Test-VSCodeInstall.ps1
    Version: 1.0.0
    Description: Performs a full diagnostic health check on the VS Code installation.
#>
function Test-VSCodeInstall {
    [OutputType([Int32])]
    [CmdletBinding()]
    param()

    Write-VSCodeUpdaterLog "[HEALTH] Starting VS Code installation health check"

    $InstallRoot = Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code"
    $CodeExe = Join-Path $InstallRoot "Code.exe"
    $PkgJson = Join-Path $InstallRoot "resources\app\package.json"
    $ProdJson = Join-Path $InstallRoot "resources\app\product.json"

    function Fail-HealthCheck {
        param([string]$Reason)
        Write-VSCodeUpdaterLog "[HEALTH] FAIL: $Reason"
        $script:LastHealthCheckState = "Failed"
        $script:LastHealthCheckReason = $Reason
        return [WatchdogExitCode]::HealthCheckFailed
    }

    if (-not (Test-Path $InstallRoot)) {
        return Fail-HealthCheck "Install root missing: $InstallRoot"
    }

    if (-not (Test-Path $CodeExe)) {
        return [WatchdogExitCode]::MissingCodeExe
    }

    if (-not (Test-Path $PkgJson)) {
        return Fail-HealthCheck "package.json missing"
    }

    try {
        $pkg = Get-Content $PkgJson -Raw | ConvertFrom-Json
    }
    catch {
        return Fail-HealthCheck "package.json unreadable or invalid JSON"
    }

    if (-not $pkg.version) {
        return Fail-HealthCheck "package.json missing version field"
    }

    $pkgVersion = $pkg.version
    Write-VSCodeUpdaterLog "[HEALTH] package.json version: $pkgVersion"

    if (-not (Test-Path $ProdJson)) {
        return Fail-HealthCheck "product.json missing"
    }

    try {
        $prod = Get-Content $ProdJson -Raw | ConvertFrom-Json
    }
    catch {
        return Fail-HealthCheck "product.json unreadable or invalid JSON"
    }

    if (-not $prod.commit) {
        return Fail-HealthCheck "product.json missing commit hash"
    }

    Write-VSCodeUpdaterLog "[HEALTH] product.json commit: $($prod.commit)"

    Write-VSCodeUpdaterLog "[HEALTH] Launching Code.exe --version"
    try {
        $proc = Start-Process -FilePath $CodeExe -ArgumentList "--version" -NoNewWindow -PassThru -Wait -ErrorAction Stop
        $exit = $proc.ExitCode
    }
    catch {
        return [WatchdogExitCode]::LaunchException
    }

    if ($exit -ne 0) {
        return [WatchdogExitCode]::LaunchFailed
    }

    try {
        $versionOutput = & $CodeExe --version 2>$null
    }
    catch {
        return [WatchdogExitCode]::LaunchException
    }

    if (-not $versionOutput) {
        return Fail-HealthCheck "Code.exe produced no version output"
    }

    $exeVersion = ($versionOutput | Select-Object -First 1).Trim()
    Write-VSCodeUpdaterLog "[HEALTH] Code.exe version: $exeVersion"

    if ($exeVersion -ne $pkgVersion) {
        return Fail-HealthCheck "Version mismatch: exe=$exeVersion pkg=$pkgVersion"
    }

    $tempWorkers = Get-ChildItem $env:TEMP -Filter "is-*" -ErrorAction SilentlyContinue
    if ($tempWorkers) {
        return Fail-HealthCheck "Leftover InnoSetup temp workers detected"
    }

    $tmpExe = Join-Path $InstallRoot "Code.exe.tmp"
    if (Test-Path $tmpExe) {
        return Fail-HealthCheck "Leftover Code.exe.tmp detected"
    }

    $partial = Get-ChildItem $InstallRoot -Directory -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^app-\d+\.\d+\.\d+-\d+$' }

    if ($partial) {
        return Fail-HealthCheck "Partial install folders detected"
    }

    $dlls = @(
        "chrome_elf.dll",
        "vcruntime140.dll",
        "msvcp140.dll"
    )

    foreach ($dll in $dlls) {
        $path = Join-Path $InstallRoot $dll
        if (-not (Test-Path $path)) {
            return Fail-HealthCheck "Missing required DLL: $dll"
        }
    }

    $symlinks = @(
        "resources\app\out",
        "resources\app\node_modules"
    )

    foreach ($link in $symlinks) {
        $path = Join-Path $InstallRoot $link
        if (-not (Test-Path $path)) {
            return Fail-HealthCheck "Broken symlink or missing path: $link"
        }
    }

    $codeProcs = Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^Code$' }

    if ($codeProcs) {
        return Fail-HealthCheck "Stale Code.exe processes detected"
    }

    $inno = Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^is-[A-Za-z0-9]+' }

    if ($inno) {
        return Fail-HealthCheck "Stale InnoSetup workers detected"
    }

    $tmp = Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^tmp$|tmp\.exe$' }

    if ($tmp) {
        return Fail-HealthCheck "Stale tmp workers detected"
    }

    $helpers = Get-Process -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -match '^CodeHelper' }

    if ($helpers) {
        return Fail-HealthCheck "Stale CodeHelper processes detected"
    }

    Write-VSCodeUpdaterLog "[HEALTH] VS Code installation is healthy"
    $script:LastHealthCheckState = "Success"
    $script:LastHealthCheckReason = $null
    return [WatchdogExitCode]::Success
}
