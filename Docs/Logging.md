# Logging Architecture

VSCode-Updater uses a deterministic, operator‑grade logging lifecycle designed for audit transparency, reproducibility, and safe diagnostics. All logs follow a strict structure, avoid sensitive information, and behave consistently across PowerShell 5.1 and PowerShell 7+. Logging now covers both the update pipeline and the multi-version management system (symlink switching, rollback, ZIP fallback, and version discovery).

---

## 1. Logging Philosophy

Logging must be:

- **Deterministic** — no randomness, no ambiguous states.
- **Machine‑readable** — grep‑friendly, line‑oriented, timestamped.
- **Cross‑platform consistent** — identical behavior on PS5.1 and PS7+.
- **Audit‑transparent** — lifecycle events clearly marked.
- **Sanitized** — no sensitive data (paths, usernames, tokens, environment details).
- **Minimal surface area** — no external dependencies or logging frameworks.

Logs reflect **what the tool knows**, not what the user prefers.  
Output mode (console vs. silent) does **not** change log content.

---

## 2. Log Location

By default, logs are written to:

C:\Logs\Update-Code.log

- Directory is created if missing.
- File is appended, not overwritten.
- Path is sanitized before use (no user-specific expansion in logs).

## 3. Log Format

Each log line follows:

```Code
[YYYY-MM-DD HH:MM:SS] [LEVEL] Message
```

### Levels

- INFO — normal lifecycle events
- WARN — recoverable issues
- ERROR — failures that stop execution
- DEBUG — internal details (only enabled with -Verbose)

**Example**

```Code
[2026-04-09 08:12:44] [INFO] Starting update lifecycle...
[2026-04-09 08:12:45] [WARN] Installer returned exit code 1638 (already installed)
[2026-04-09 08:12:46] [INFO] Update completed successfully.
```
### 3.1 Multi-Version Logging

The logging system now includes structured entries for version-management operations:

- **Version Discovery**
  Logged when scanning for installed VS Code versions:

```
[INFO] Discovered 3 installed VS Code versions
```

- **Symlink Switching**
Logged when updating the active version:

```
[INFO] Switching active version → 1.90.0
[INFO] Symlink updated: vscode.exe → C:\Apps\VSCode\1.90.0\
```

- **Rollback**
Logged when reverting to a previous version:

```
[WARN] Rolling back to previous version: 1.89.1
```

- **ZIP Fallback**
Logged when the fallback installer is invoked:

```
[WARN] EXE installer failed — invoking ZIP fallback
[INFO] Extracted ZIP to <vscode>\1.90.0-fallback\
```

All multi-version logs follow the same sanitization and timestamp rules as the update pipeline.

## 4. Lifecycle Banners
Lifecycle banners mark major phases of execution.

**Start Banner**

```Code
2026-04-17 17:09:53 ===============================================================================
2026-04-17 17:09:53   Update-VSCode started — Version 2.0.0
2026-04-17 17:09:53   Host: <Name of Host Machine>
2026-04-17 17:09:53   User: <Name of User Running the Script>
2026-04-17 17:09:53   RetryCount=3  IdleTimeout=600
2026-04-17 17:09:53 ===============================================================================
```

**Start Banner Fields**

- Timestamp
- Script version
- Host machine
- User
- RetryCount
- IdleTimeout

**Stop Banner**

```Code
2026-04-17 17:36:14 ----- Update-VSCode ended (exit 30) -----
```

**Stop Banner Fields**

- Timestamp
- Exit code
- Includes stall reason (FS‑Stalled, Idle‑Stalled, Active‑Stalled, Normal)   

**Watchdog Banner**

```Code
2026-04-17 17:13:47 [WATCHDOG] File system activity detected — resetting timers
2026-04-17 17:36:14 [WATCHDOG] No filesystem activity for 600 seconds — killing installer
2026-04-17 17:36:14 [WATCHDOG] Filesystem stall detected — no writes for 600 seconds
```

Rules:

- Banners are always single-line.
- No sensitive data may appear in banners.
- Version is included for audit traceability.

### Watchdog Logging Behavior

The watchdog emits structured log entries during installer monitoring:

- **Activity Detection**
  ```Code
  [WATCHDOG] File system activity detected — resetting timers
  ```
  Printed when meaningful writes occur in the VS Code installation directory.
  This message is rate‑limited by fsLogCooldown (default: 30 seconds).

- **Filesystem Stall Detection**
If no meaningful writes occur for IdleTimeout seconds:

  ```Code
  [WATCHDOG] No filesystem activity for <IdleTimeout> seconds — killing installer
  [WATCHDOG] Filesystem stall detected — no writes for <IdleTimeout> seconds
  ```
This results in exit code 30.

- **Idle Stall Detection**
  ```Code
  [WATCHDOG] CPU/Disk idle stall — no activity for <IdleTimeout> seconds
  ```
  Exit code 31.

- **Active Stall Detection**
  ```Code
  [WATCHDOG] CPU/Disk active stall — metrics frozen for <IdleTimeout> seconds
  ```
Exit code 32.

### Installer Integrity Logging

VSCode-Updater logs additional diagnostics when installer integrity checks fail:

- **Stale Installer (age > 7 days)**

```
[WARN] Cached installer is stale — age: 12 days
```

- **Corrupted Download (size < 5MB)**

```
[ERROR] Installer appears truncated — size: 1.2 MB
```

These checks prevent silent failures and ensure deterministic behavior.


## 5. Sanitization Requirements

Logs must never contain:

- Usernames
- Full local paths
- Environment variables
- Tokens, secrets, or credentials
- Machine‑specific identifiers
- Raw installer arguments

Allowed:

- Installer exit codes
- Sanitized relative paths
- High‑level state transitions
- Watchdog events
- Timing information

**Example of sanitized path**

Instead of:

```Code
C:\Users\%USER%\AppData\Local\Temp\vscode_installer.exe
```

Log:

```Code
<temp>\vscode_installer.exe
```

## 6. Watchdog Logging

The watchdog monitors installer execution and logs:

- start of monitoring
- elapsed time
- stall detection
- forced termination
- installer exit code (if available)

**Example**

```Code
[2026-04-09 08:12:50] [INFO] Watchdog started (timeout: 120s)
[2026-04-09 08:14:50] [WARN] WATCHDOG: Installer stalled, terminating process...
[2026-04-09 08:14:51] [INFO] WATCHDOG: Process terminated successfully.
```

Rules:

- Watchdog logs must be timestamped.
- No process IDs or sensitive system details may be logged.
- Stall detection must be explicit and unambiguous.

### Retry Ceiling Logging

If the user specifies a RetryCount higher than the module's hard ceiling (default: 5), the value is clamped and logged:

```
[WARN] RetryCount=12 exceeds maximum allowed (5) — clamping to 5
```

If all retries are exhausted:

```
[ERROR] Retry limit reached — installer stalled across all attempts
```

## 7. Exit-Code Logging

Installer exit codes are normalized into deterministic module exit states.

**Example**

```Code
[2026-04-09 08:12:45] [INFO] Installer returned exit code 0 (success)
[2026-04-09 08:12:45] [INFO] Normalized exit state: Success
```

Mapping Table (example)
| Installer Code | Meaning         | Normalized State |
|----------------|-----------------|------------------|
| 0              | Success         | Success          |
| 1638           | Already installed | Success          |
| 1603           | Fatal error     | Failure          |
| Timeout        | Watchdog termination | Failure          |

All mappings must be documented in docs/Design.md.

## 8. Verbose Mode

Verbose mode (-Verbose) adds:

- DEBUG-level lines
- internal decision points
- timing details

Verbose logs must still follow sanitization rules.

Example:

```Code
[DEBUG] Download URL resolved to stable channel
[DEBUG] Installer path: <temp>\vscode_installer.exe
```

## 9. Log Rotation

VSCode-Updater uses a simple rotation strategy:

- Maximum log size: **5 MB**
- When exceeded:
 - VSCode-Updater.log → VSCode-Updater.log.1
 - New log file created

Rotation events are logged:

```Code
[INFO] Log rotated: VSCode-Updater.log → VSCode-Updater.log.1
```

## 10. Failure Logging

Failures must include:

- clear error message
- normalized exit state
- sanitized context
- watchdog involvement (if applicable)

Example:

```Code
[ERROR] Installer failed with exit code 1603 (fatal error)
[INFO] Normalized exit state: Failure
```

## 11. Dashboard Logging

`Get-VSCodeDashboard` produces structured, read-only diagnostic output.  
Dashboard logs include:

- active version
- installed versions
- symlink status
- installer cache state
- last update result
- watchdog metrics (if available)

Dashboard output is informational only and does not modify system state.


## 12. Summary

The logging system is designed to be:

- deterministic
- safe
- predictable
- audit‑friendly
- cross‑platform
- sanitized

The logging system is designed to be deterministic, safe, predictable, audit‑friendly, and consistent across all supported runtimes. Logging now covers both the update pipeline and the multi-version management system, ensuring complete traceability for updates, rollbacks, symlink operations, fallback installs, and diagnostics.

