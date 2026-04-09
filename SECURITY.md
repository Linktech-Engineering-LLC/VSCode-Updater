# Security Policy

This document outlines the security policy for **VSCode-Updater**, including supported versions, reporting procedures, and expectations for responsible disclosure.

The project follows an operator‑grade security philosophy: deterministic behavior, predictable failure modes, and strict avoidance of unnecessary attack surface.

---

## 🔐 Supported Versions

Only the latest published release receives security updates.

| Version | Supported |
|--------|-----------|
| v2.x   | ✔ Active support |
| v1.x   | ✖ No longer supported |

Security fixes are applied only to the most recent stable release.  
Older versions will not receive patches.

---

## 🛡 Security Expectations

Contributions and changes must adhere to the following principles:

- **No external dependencies** unless explicitly approved.
- **No execution of remote code** beyond the VS Code installer itself.
- **No unvalidated input** passed to system commands or external processes.
- **No sensitive data** written to logs (paths, usernames, tokens, environment details).
- **Fail closed** — errors must be deterministic and safe.
- **Silent installer behavior must remain hardened** and predictable.
- **Watchdog logic must not expose system internals** beyond what is required for diagnostics.

Any change that affects installer execution, logging, or process control must undergo additional review.

---

## 📣 Reporting a Vulnerability

If you discover a security issue, please report it privately.

**Do not open a public GitHub issue.**

Instead, contact the project maintainer directly:

**ldmcclatchey@linktech.engineering**

Please include:

- A clear description of the issue  
- Steps to reproduce (if applicable)  
- Potential impact  
- Suggested remediation (optional)

You will receive an acknowledgment within **72 hours**, and a full response within **7 days**, depending on severity.

---

## 🤝 Responsible Disclosure

We request that you:

- Allow reasonable time for investigation and remediation  
- Avoid publicly disclosing details until a fix is released  
- Avoid exploiting the vulnerability beyond what is necessary for proof‑of‑concept  

Once a fix is published, you may disclose the issue publicly if desired.

---

## 🔄 Security Update Process

1. Vulnerability is reported privately  
2. Maintainer investigates and confirms severity  
3. Patch is developed and tested  
4. A new release is tagged and published  
5. CHANGELOG is updated with a security entry  
6. Public disclosure (if applicable)

---

## 🧩 Scope

This policy applies to:

- The PowerShell module  
- All scripts under `Public/` and `Private/`  
- Documentation that affects security posture  
- Release artifacts and installer orchestration logic

It does **not** apply to:

- Visual Studio Code itself  
- Microsoft’s installer binaries  
- Third‑party extensions or plugins

---

## 📘 Additional Notes

VSCode-Updater is designed to be deterministic and audit‑transparent.  
Any behavior that introduces ambiguity, nondeterminism, or unnecessary risk will be treated as a security concern.

Thank you for helping keep this project secure.
