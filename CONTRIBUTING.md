# Contributing to VSCode-Updater

Thank you for your interest in contributing to **VSCode-Updater**.  
This project follows an operator‑grade engineering philosophy: deterministic behavior, predictable failure modes, clear logging, and reproducible workflows. Contributions should align with these principles.

---

## 📌 Guiding Principles

- **Determinism** — No hidden behavior, no magic strings, no ambiguous states.
- **Operator-Grade Reliability** — Clear logs, predictable exit codes, hardened error handling.
- **Minimal Surface Area** — No unnecessary dependencies or complexity.
- **Cross-Platform Stability** — PowerShell 5.1 and 7+ must behave consistently.
- **Audit Transparency** — All logic must be traceable, testable, and documented.

---

## 🧱 Repository Structure

VSCode-Updater/
│
├── VSCode-Updater.psd1        # Module manifest
├── VSCode-Updater.psm1        # Module loader
├── Public/                    # Public functions (exported)
├── Private/                   # Internal helpers (not exported)
├── docs/                      # Architecture, logging, design notes
├── CHANGELOG.md               # Version history
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── SECURITY.md
└── README.md

Code

### Rules:
- **Public functions** must live in `/Public` and be exported via the manifest.
- **Private functions** must live in `/Private` and must not be exported.
- **No logic in the module root** — only imports and scaffolding.
- **No external dependencies** unless explicitly approved.

---

## 🛠️ Development Workflow

### 1. Fork → Branch → Commit → PR
Use the following branching model:

main        # stable, release-ready
dev         # active development
feature/*   # individual features or fixes

Code

Example:

feature/logging-enhancements

Code

### 2. Commit Message Convention

Use clear, descriptive commit messages:

Add: new watchdog stall detection
Fix: incorrect exit code mapping for installer failures
Update: logging lifecycle banners
Remove: deprecated non-deterministic update logic
Docs: add Design.md and Logging.md

Code

Avoid vague messages like “misc fixes” or “update script”.

---

## 🧪 Testing Requirements

All contributions must:

- Run cleanly on **PowerShell 5.1** and **PowerShell 7+**
- Produce deterministic logs
- Respect the module’s exit-code contract
- Avoid breaking silent-install behavior
- Avoid introducing non-deterministic timing or race conditions

If your change affects:

- logging  
- exit codes  
- installer behavior  
- watchdog logic  

…you must update the relevant documentation in `/docs`.

---

## 📄 Documentation Requirements

Any change that affects behavior must update:

- `README.md`  
- `CHANGELOG.md`  
- `docs/Design.md` (architecture)  
- `docs/Logging.md` (lifecycle, banners, exit codes)

Documentation must be:

- concise  
- operator-grade  
- free of ambiguity  
- consistent with existing tone  

---

## 🔐 Security and Hardening

All contributions must:

- Avoid introducing external attack surfaces
- Validate all inputs
- Fail safely and predictably
- Never expose sensitive paths or environment details in logs

See `SECURITY.md` for reporting vulnerabilities.

---

## 🧾 Pull Request Requirements

Every PR must include:

- A clear description of the change
- Why the change is needed
- Testing notes (PS5.1 + PS7+)
- Updated documentation (if applicable)
- Updated CHANGELOG entry (under `[Unreleased]`)

PRs that do not meet these requirements may be closed.

---

## 🧭 Versioning and Release Workflow

This project uses **Semantic Versioning**.

### Release steps:

1. Update `CHANGELOG.md`
2. Ensure all docs are complete
3. Ensure module manifest is correct
4. Commit and push all changes
5. Create an annotated tag:

git tag -a vX.Y.Z -m "VSCode-Updater vX.Y.Z"
git push origin vX.Y.Z

Code

6. Draft a GitHub Release and paste the Release Notes

---

## 🤝 Code of Conduct

Participation in this project is governed by the  
**Contributor Covenant Code of Conduct v2.1** (see `CODE_OF_CONDUCT.md`).

---

## 📬 Questions or Proposals

For major changes, open a **Discussion** or **Issue** before submitting a PR.  
For security concerns, contact:

**ldmcclatchey@linktech.engineering**
