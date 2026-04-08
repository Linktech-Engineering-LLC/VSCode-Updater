# VSCode-Updater

![PowerShell](https://img.shields.io/badge/PowerShell-7.6%2B-blue)
![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey)
![Status](https://img.shields.io/badge/Status-Active-success)
![License](https://img.shields.io/badge/License-MIT-green)
![Last Commit](https://img.shields.io/github/last-commit/Linktech-Engineering-LLC/VSCode-Updater)

A deterministic, operator‑grade PowerShell module for safely updating Visual Studio Code with full 
logging, cleanup routines, and a multi‑lane watchdog to detect installer stalls.

## Features

- Fully automated VSCode update workflow  
- Deterministic logging with timestamped entries  
- Cleanup routines for bootstrapper, helpers, and Inno workers  
- Three‑lane watchdog monitoring:
 - Filesystem stall detection
 - CPU/Disk idle stall detection
 - CPU/Disk active stall detection
- Safe, explicit return codes for automation and diagnostics
- Pester test suite for all critical components
- Single public API (Update-VSCode) with all helpers private by design

## Requirements

- PowerShell 7.6 or later  
- Windows 10/11  

## Usage

### Importing the Module

The module exposes a single public entry point. Import it from any location:

```powershell
Import-Module VSCode-Updater -Force
```

Or import directly from your project tree:

```powershell
Import-Module "$HOME\Nextcloud\Projects\Scripts\PowerShell\VSCode-Updater\VSCode-Updater.psd1" -Force
```

### Running the Updater

Invoke the orchestrator:

```powershell
Update-VSCode
```

This triggers the full deterministic update pipeline:

* Cleanup of bootstrapper, helpers, and Inno workers
* Optional skip/force download modes
* Installer acquisition and caching
* Detached installer launch
* Watchdog monitoring of installer progress
* Automatic stall detection and recovery
* Final cleanup and exit code emission

No parameters are required.
All helper functions remain private by design.

### Verifying Module Load

Confirm the module exported only the public API:

```powershell
Get-Command -Module VSCode-Updater
```

Expected output:

```Code
Function  Update-VSCode
```

*Example: Updating VS Code from Anywhere*

If the module is placed under your PowerShell module path:

```Code
$HOME\Documents\PowerShell\Modules\VSCode-Updater\
```

PowerShell auto‑loads it, allowing:

```powershell
Update-VSCode
```

from any shell without manual imports.

### Example Output

A typical successful run produces single‑line, timestamped entries similar to:

```Code
[2025-03-27 09:14:22] INFO  Detected installed version: 1.89.1
[2025-03-27 09:14:23] INFO  Latest version available: 1.90.0
[2025-03-27 09:14:24] INFO  Downloaded installer to: C:\Temp\vscode.exe
[2025-03-27 09:14:31] INFO  Update completed successfully
```

All output is audit‑transparent and automation‑safe.

## Watchdog Behavior

The updater includes a multi‑lane watchdog that monitors the installer for progress and stalls.

### Stall Conditions

| Stall Type | Description |
| :--- | :--- |
| Filesystem Stall | No writes to the VS Code install directory for the full IdleTimeout |
| Idle Stall | CPU=0 and Disk=0 for the full IdleTimeout |
| Active Stall | CPU/Disk metrics frozen (no change) for the full IdleTimeout |

Each stall type produces a distinct return code and log entry.

## Return Codes

| Code | Meaning |
| :---: | :--- |
| 0 | Success |
| 10 | Download failure |
| 12 | Cached installer missing |
| 13 | Installer start failure |
| 14 | Installer stalled after all retries |
| 20 |	SkipUpdate flag used |
| 30 |	Filesystem stall detected by watchdog |
| 31 |	CPU/Disk idle stall detected by watchdog |
| 32 |	CPU/Disk active stall detected by watchdog |
| 99 |	Unexpected watchdog state |

These codes are deterministic and safe for automation, scripting, and monitoring.

## Logging Behavior

- Single‑line, timestamped entries
- No banners or multi‑line blocks
- All watchdog transitions logged
- All exit paths emit a final banner with exit code
- Fully audit‑transparent

## Development Status

This module is stable and feature‑complete.  
Tests and documentation are actively expanding as it approaches first production deployment.

## Running Tests

```powershell
Invoke-Pester -Path Tests
```

## License

This project is licensed under the MIT License.  
See the [LICENSE](LICENSE) file for details.
