# Changelog
All notable changes to **VSCode-Updater** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to **Semantic Versioning**.

---

## [2.0.0] - 2026-04-09
### Added
- **Deterministic watchdog** for monitoring installer execution:
  - Detects stalls, hung installers, and non‑terminating processes.
  - Enforces a strict timeout window with controlled termination.
- **Operator‑grade logging lifecycle**:
  - Unified log format across PS5.1 and PS7+.
  - Timestamped lifecycle banners for start, stop, and watchdog events.
  - Explicit log path override support.
- **Exit‑code mapping layer**:
  - Normalizes installer return codes into predictable module exit states.
  - Provides clean, single‑line status output for automation systems.
- **Cross‑platform compatibility**:
  - Fully supported on Windows PowerShell 5.1 and PowerShell 7+.
  - Hardened behavior on Windows 10/11 and Server 2016–2025.
- **Silent installer orchestration**:
  - Bypasses VS Code’s internal updater.
  - Ensures deterministic, unattended updates.

### Changed
- Rewrote internal download logic for reliability and predictable failure modes.
- Consolidated helper functions under `Private/` with strict scoping.
- Improved module manifest (`.psd1`) with accurate metadata and exports.
- Updated README.md to reflect new architecture and usage patterns.

### Removed
- Legacy, non‑deterministic update logic.
- Any reliance on VS Code’s built‑in update mechanism.

---

## [1.0.0] - 2025-11-14
### Added
- Initial release of **VSCode-Updater** with:
  - Basic update workflow.
  - Silent installer support.
  - Simple logging.
  - PowerShell module structure.

---

## [Unreleased]
- Additional logging enhancements.
- Optional verbose diagnostics mode.
- Extended installer telemetry.
