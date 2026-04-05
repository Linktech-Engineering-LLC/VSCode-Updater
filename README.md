# VSCode-Updater

![PowerShell](https://img.shields.io/badge/PowerShell-7.6%2B-blue)
![Platform](https://img.shields.io/badge/Platform-Windows-lightgrey)
![Status](https://img.shields.io/badge/Status-Active-success)
![License](https://img.shields.io/badge/License-MIT-green)
![Last Commit](https://img.shields.io/github/last-commit/Linktech-Engineering-LLC/VSCode-Updater)

A deterministic, operator‑grade PowerShell module for safely updating Visual Studio Code with full logging, cleanup routines, and watchdog monitoring.

## Features

- Fully automated VSCode update workflow  
- Deterministic logging with timestamped entries  
- Cleanup routines for bootstrapper, helpers, and Inno workers  
- Watchdog monitoring for installer completion  
- Safe return codes for automation and monitoring  
- Pester test suite for all critical components  

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

* Detect installed VS Code
* Query latest available version
* Download and validate installer
* Stop running VS Code instances
* Execute silent update
* Watchdog‑monitor installer completion
* Cleanup bootstrapper, helpers, and temp artifacts
* Emit operator‑grade logs and return codes

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

## Return Codes

| Code | Meaning |
|------|---------|
| 0    | Success |
| 10   | Download failure |
| 20   | SkipUpdate flag used |

## Logging Behavior

- Single‑line, timestamped entries  
- No multi‑line banners  
- Operator‑grade, audit‑transparent output  

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
