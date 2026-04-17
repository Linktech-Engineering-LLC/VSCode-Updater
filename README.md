# VSCode-Updater

![PowerShell](https://img.shields.io/badge/PowerShell-7.6%2B-blue)
![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey)
![Status](https://img.shields.io/badge/Status-Active-success)
![License](https://img.shields.io/badge/License-MIT-green)
![Last Commit](https://img.shields.io/github/last-commit/Linktech-Engineering-LLC/VSCode-Updater)

A deterministic, operator‑grade PowerShell module for safely updating Visual Studio Code on Windows.  
Provides full logging, cleanup routines, installer caching, and a multi‑lane watchdog to detect and recover from installer stalls.

---

## Why This Exists

The built‑in Visual Studio Code updater frequently fails on long‑lived Windows systems due to:

- stale bootstrapper processes  
- orphaned InnoSetup workers  
- partial or corrupted installs  
- silent failures with no diagnostics  
- reissued builds that reuse the same version number  
- inconsistent behavior across Windows update states  

These issues cause VS Code to hang, refuse to launch, or leave behind incomplete installations.

**VSCode-Updater replaces the non‑deterministic built‑in updater with a reproducible, watchdog‑driven update pipeline designed for operators, automation, and audit transparency.**

---

## Features

- Fully automated VS Code update workflow  
- Deterministic logging with timestamped, single‑line entries  
- Cleanup routines for bootstrapper, helpers, and Inno workers  
- Installer acquisition and caching  
- Detached installer execution  
- Multi‑lane watchdog monitoring:
  - Filesystem stall detection  
  - CPU/Disk idle stall detection  
  - CPU/Disk active stall detection  
- Automatic stall recovery and retry logic  
- Explicit, automation‑safe return codes  
- Pester test suite for critical components  
- Single public API (`Update-VSCode`) with all helpers private by design  

---

## Requirements

- PowerShell 7.6 or later  
- Windows 10 or Windows 11  

---

## Installation

You can use the module in two ways:

### 1. Install into a PowerShell module path (auto‑load)

Place the module under a standard module directory, for example:

`$HOME\Documents\PowerShell\Modules\VSCode-Updater\`

PowerShell will auto‑load it when you call:

No explicit Import-Module is required in this case.

### 2. Use from a custom location (explicit import required)
If the module lives in a custom path (for example, under a project tree or sync folder), you must import it before calling Update-VSCode:

```powershell
Import-Module "C:\Path\To\VSCode-Updater\VSCode-Updater.psd1" -Force

Update-VSCode
```

The function cannot be executed until the module is imported (either auto‑loaded from a module path or imported explicitly).

## Usage

### Basic Invocation

```powershell
Update-VSCode
```

This triggers the full deterministic update pipeline:

- Cleanup of stale installer processes
- Optional skip/force download modes
- Installer download and caching
- Detached installer launch
- Watchdog monitoring of progress
- Stall detection and recovery
- Final cleanup and exit code emission

No parameters are required for a standard update run.  

However, parameters are available for advanced control (see below).

### Parameters

Update-VSCode exposes optional parameters for operator and automation scenarios.
(Adjust this list to match your actual parameter set.)

```powershell
Update-VSCode [
    -SkipUpdate
    -SkipDownload
    -ForceDownload
    -RetryCount <int>
    -IdleTimeout <int>
]
```

### Parameter Details

- `-SkipUpdate`
Bypasses the update process entirely.
Useful when you want to run cleanup routines or validate environment behavior without performing an update.

- `-SkipDownload`
Uses an already‑cached installer.
No network request is made.
If no cached installer exists, return code 12 is emitted.

- `-ForceDownload`
Always downloads a fresh installer, ignoring any cached copy.
Overrides -SkipDownload if both are provided.

- `-RetryCount <int>` (default: 3)
Number of retry attempts the watchdog will perform if a stall is detected.

- `-IdleTimeout <int>` (default: 600 seconds)
Maximum allowed stall duration before the watchdog triggers a retry or failure.
Applies to filesystem, idle, and active stall detection lanes.

All parameters are optional.
If you call `Update-VSCode` with no arguments, the module runs with its default, deterministic behavior.

## Verify Module Load

```powershell
Get-Command -Module VSCode-Updater
```

Expected:

`Function  Update-VSCode`

## Example Output

A typical successful run:

```
[2025-03-27 09:14:22] INFO  Detected installed version: 1.89.1
[2025-03-27 09:14:23] INFO  Latest version available: 1.90.0
[2025-03-27 09:14:24] INFO  Downloaded installer to: C:\Temp\vscode.exe
[2025-03-27 09:14:31] INFO  Update completed successfully
```

All output is automation‑safe and audit‑transparent.

## Architecture Overview

VSCode-Updater uses a four‑lane deterministic pipeline:

1. Discovery Lane

    - Detect installed version
    - Query latest available version
    - Validate cached installer

2. Acquisition Lane

    - Download installer if required
    - Cache installer for reuse
    - Validate file integrity

3. Execution Lane

    - Launch installer in detached mode
    - Track installer PID
    - Monitor filesystem and resource activity

4. Watchdog Lane

    - Filesystem stall detection
    - CPU/Disk idle stall detection
    - CPU/Disk active stall detection
    - Automatic retries
    - Deterministic exit codes

### Watchdog Behavior

The watchdog monitors the installer for progress and detects stalls using three independent signals.

#### Stall Conditions

|  Stall Type | Description |
| :--- | :--- |
| Filesystem Stall | No writes to the VS Code install directory for the full IdleTimeout |
| Idle Stall | CPU=0 and Disk=0 for the full IdleTimeout |
| Active Stall | CPU/Disk metrics frozen (no change) for the full IdleTimeout |

Each stall type produces a distinct return code and log entry.

#### Return Codes

| Code | Meaning |
| :---: | :--- |
| 0 | Success |
| 10 | Download failure |
| 12 | Cached installer missing |
| 13 | Installer start failure |
| 14 | Installer stalled after all retries |
| 20 | SkipUpdate flag used |
| 30 | Filesystem stall detected |
| 31 | CPU/Disk idle stall detected |
| 32 | CPU/Disk active stall detected |
| 99 | Unexpected watchdog state |

These codes are deterministic and safe for automation, monitoring, and CI/CD pipelines.

#### Logging Behavior

- Single‑line, timestamped entries
- No banners or multi‑line blocks
- All watchdog transitions logged
- All exit paths emit a final banner with exit code
- Fully audit‑transparent

#### Compatibility

| Component | Supported |
| :--- | :---: |
| Windows 10 |	✔ |
| Windows 11	| ✔ |
| VS Code Stable	| ✔ |
| VS Code Insiders 	| ⚠ Not supported (Stable installer will overwrite Insiders) |
| PowerShell 7.6+	| ✔ |
| ARM64	| ⚠ Untested (expected to work with ARM64 user installer) |

## Development Status

This module is stable and feature‑complete.
Tests and documentation continue to expand as it moves toward broader deployment.

## Running Tests

```powershell
Invoke-Pester -Path Tests
```

## License

This project is licensed under the MIT License.
See the LICENSE file for details.

## Related Projects

These tools are part of the Linktech Engineering operator‑grade ecosystem:

- [NMS_Tools](https://github.com/Linktech-Engineering-LLC/NMS_Tools) — Network Monitoring Suite tools for certificate checks, HTML checks, interface checks, and more.
- [rust-logger](https://github.com/Linktech-Engineering-LLC/rust-logger) — Structured, deterministic logging library for Rust applications.
- [licensegen](https://github.com/Linktech-Engineering-LLC/licensegen) — Deterministic license generator with reproducible output and SPDX‑compliant metadata.
- [BotScanner-Community](https://github.com/Linktech-Engineering-LLC/BotScanner-Community) — Community edition of the BotScanner host and flow inspection framework.
