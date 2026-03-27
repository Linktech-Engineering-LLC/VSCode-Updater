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
