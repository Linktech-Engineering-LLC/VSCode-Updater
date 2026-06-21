# Changelog
All notable changes to **VSCode-Updater** will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to **Semantic Versioning**.

---

## [2.1.0] - 2026-06-20
### Added
- Introduced full multi-version management support:
  - `Get-VSCodeVersions` — Enumerates all detected VS Code installations.
  - `Switch-VSCodeVersion` — Switches the active VS Code version via symlink control.
  - `Invoke-VSCodeRollback` — Performs deterministic rollback to the previously active version.
  - `Test-VSCodeSymlink` — Validates symlink integrity, permissions, and target correctness.
  - `Start-VSCodeSafeMode` — Launches VS Code with extensions disabled for diagnostics.
  - `Get-VSCodeDashboard` — Displays a structured diagnostic dashboard for operators.
  - `Invoke-ZipFallback` — ZIP-based fallback installer for environments where the EXE installer fails.
- Added symlink-based version switching architecture with deterministic behavior.
- Added version discovery layer for Stable, User, System, and ZIP installations.
- Added rollback metadata tracking for safe, reversible transitions.
- Added dashboard aggregation for update history, cache state, and watchdog metrics.

### Changed
- Updated module exports to include new public commands.
- Updated README.md to reflect expanded command surface and multi-version capabilities.
- Improved installer cache validation to support multiple parallel versions.

### Fixed
- Corrected edge cases where stale symlink targets could persist after failed updates.
- Improved fallback logic when installer metadata is missing or corrupted.

## [2.0.1] - 2026-05-05
### Changed
- Updated module manifest metadata for PowerShell Gallery publishing.
- Bumped ModuleVersion to 2.0.1.
- Added publish workflow trigger and manual dispatch support.
- Added hard retry ceiling (`$MaxRetries = 5`) with clamping and warning when user-specified RetryCount exceeds limit.
- Added diagnostic for retry exhaustion when installer stalls across all allowed attempts.
- Added detection for stale cached installers (age > 7 days) to identify debris from past failed updates.
- Added corrupted-download detection (installer size < 5MB) to catch incomplete or truncated downloads.
- Added stale install-directory timestamp detection to identify silent installer failures.

### Fixed
- Corrected manifest GUID and metadata fields required by the Gallery.

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
- No changes yet.
