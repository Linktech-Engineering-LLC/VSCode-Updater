# VSCode‑Updater Documentation Index

This directory contains the full technical documentation for VSCode‑Updater, including architecture, design principles, logging behavior, version‑management internals, and release history.
All documents follow deterministic, operator‑grade standards consistent with the module’s behavior.

## 📘 Core Documents

### 1. Design & Architecture

**File:** [Design](Design.md)

Describes the internal architecture of VSCode‑Updater, including:
* Deterministic update pipeline
* Multi‑version architecture
* Symlink controller
* Rollback metadata
* ZIP fallback installer
* Watchdog model
* Exit‑code normalization
* Security boundaries

This is the authoritative reference for how the module works internally.

### 2. Logging Model

**File:** [Logging](Logging.md)

Defines the complete logging lifecycle:
* Log format and sanitization rules
* Lifecycle banners
* Watchdog logging
* Multi‑version logging (switching, rollback, fallback)
* Retry‑ceiling warnings
* Installer integrity diagnostics
* Log rotation behavior

All logging behavior is deterministic and audit‑transparent.

## 📦 Module Overview

### 3. Changelog

**File:** [CHANGELOG](../CHANGELOG.md)

Tracks all notable changes across releases, following Keep‑a‑Changelog and SemVer.

Includes:
* 2.1.0 multi‑version support
* 2.0.x watchdog and deterministic pipeline
* Historical release notes

### 4. README (Public Overview)

**File:** [README](../README.md)

The public‑facing overview of the module, including:
* Features
* Requirements
* Installation
* Usage
* Public commands
* Examples
* Compatibility
* Related projects

This is the entry point for new users.

## 🧩 Public Command Surface

VSCode‑Updater exposes the following operator‑grade commands:
* ``Update-VSCode`` — Deterministic update pipeline
* ``Get-VSCodeVersions`` — Enumerate installed versions
* ``Switch-VSCodeVersion`` — Symlink‑based version switching
* ``Invoke-VSCodeRollback`` — Deterministic rollback
* ``Test-VSCodeSymlink`` — Validate symlink integrity
* ``Start-VSCodeSafeMode`` — Launch VS Code with extensions disabled
* ``Get-VSCodeDashboard`` — Structured diagnostic dashboard
* ``Invoke-ZipFallback`` — ZIP‑based fallback installer

Each command is documented in the README and referenced in the design and logging docs.

## 🛠 Internal Structure

### 5. Public Commands
**Directory:** `Public/`  
Contains one PowerShell script per exported command.

### 6. Private Helpers
**Directory:** `Private/`  
Contains internal implementation functions used by the update pipeline, watchdog, and version‑management system.

### 7. Tests
**Directory:** `Tests/`  
Contains Pester tests validating update behavior, watchdog logic, version switching, rollback, and fallback.

### 8. Tools
**Directory:** `Tools/`  
Included in the repository. Contains build helpers, packaging utilities, and development tools.

## 📄 Additional Files

* [SECURITY](../SECURITY.md) — Security posture and boundaries
* [LICENSE](../LICENSE) — MIT license
* [Publisher](../.github/workflows/publish.yml) — Gallery publishing workflow
* [Tests Workflow](../.github/workflows/tests.yml) — Automated Pester test pipeline

## 📚 Summary

This documentation set provides:
* A complete architectural reference
* Deterministic logging model
* Full version‑management internals
* Update pipeline behavior
* Release history
* Public command documentation

VSCode‑Updater is engineered for deterministic execution, hardened silent installs, predictable failure modes, and operator‑grade reliability across Windows environments.