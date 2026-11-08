---
name: revit-install-mcp
description: Install and connect the Revit MCP server (mcp-server-for-revit-python, pyRevit Routes) to Claude on a new Windows machine, fix a broken install, or check why Revit-Connector is not working. Use when asked to install, set up, reinstall or connect Revit MCP / Revit-Connector / cài MCP Revit, kết nối Revit với Claude, cài trên máy mới.
---

# Revit: Install MCP

Type: **setup skill** (changes the user's machine and Claude config, never the Revit model). Follows `docs/safety-rules.md` sections 1 and 4: nothing is changed without the user's confirmation, and no secrets are written anywhere.

Bundled files (all inside this skill folder):
- `scripts/install-revit-mcp.ps1` - the installer (8 steps, safe to re-run).
- `references/install-guide.md` - full guide: prerequisites, options, troubleshooting, rollback. Read it when a step fails.

## When to use
- Installing Revit MCP on a new or colleague's machine.
- `Revit-Connector` is missing in Claude Desktop, or `get_revit_status` fails.
- Reinstalling after a pyRevit or Claude Desktop reinstall.

## Workflow

1. **Pre-check (read-only).** Ask the user to run, or run it yourself if a device shell is available: `winget --version`, `git --version`, `uv --version`. Also confirm: Windows, pyRevit installed, Revit opened at least once, Claude Desktop signed in, Revit and pyRevit versions. Do not assume the machine has winget: the script falls back to the official Git for Windows installer and the astral.sh `uv` installer, and asks the user to approve each (use `-Yes` only if the user asks for an unattended run).
2. **Clarify (max 5 questions).** Work or home machine (work: IT approval needed)? Admin rights available (firewall rule)? Which extension version, see the table below. State the assumption and continue if the answer is obvious.
3. **Prerequisites.** The script installs a missing Git or uv itself after approval. Only if that fails, use the manual steps in the guide (section 2), then open a **new** PowerShell so PATH is refreshed.
4. **Preview, then confirm.** Tell the user what the script will change: install Git and uv if missing (with approval), clone into `%APPDATA%\pyRevit\Extensions`, install Python 3.13 + dependencies with `uv`, set `[routes] enabled = true` in `pyRevit_config.ini` (`.bak` kept), add `Revit-Connector` to `claude_desktop_config.json` (`.bak` kept, other servers kept) and to Claude Code if present, add a firewall rule for port 48884. Wait for approval.
5. **Run** (user closes Revit and Claude Desktop first):
   `powershell -ExecutionPolicy Bypass -File "<path>\install-revit-mcp.ps1" -UseMaster`
   Use PowerShell "Run as administrator" if the firewall rule is wanted. Do not edit the script or change options without telling the user.
6. **After install.** Fully restart Revit (not "Reload pyRevit"), open a model, fully quit and reopen Claude Desktop, click MCP > Bridge > Connect (master version), start a new chat.
7. **Verify (read-only).** Call `get_revit_status`; expect `active` / `healthy`. Then `get_revit_model_info`. Report what was verified and what was not.

## Extension version

| Option | Flag | Pros | Cons |
|---|---|---|---|
| Latest (`master`) | `-UseMaster` | Authentication, approval prompt in Revit before model changes and Python execution | Needs pyRevit that forwards HTTP headers; 408 error on some pyRevit versions |
| Pre-pairing (`4e8ec5f`) | default | Works with pyRevit 6.5.2 | No authentication, no approval prompt |

Pick: try `-UseMaster` first; fall back to the default only if the 408 error appears, and tell the user about the security trade-off.

## Expected output
Short report: what was installed or fixed, version chosen and why, verification result, remaining manual steps (restart, Connect).

## Notes
- Script console messages are unaccented Vietnamese; the translation table is in the guide.
- Never run the script from a cloud workspace for the user's machine; it must run on the user's own PowerShell.
- Never disable the firewall rule, never expose port 48884 or the HTTP transport to a network.
- Does NOT save, sync or close any Revit document.
- If a step fails, read the matching row in the guide's troubleshooting table before retrying; do not repeat the same failing command.

## Tested on
- Original machine (author notes): Revit 2024.3, pyRevit 6.5.2, Claude Desktop on Windows.
- Verified so far: PowerShell syntax parses with no errors; logic reviewed. NOT yet run end-to-end: the Git / uv fallback (no winget) and the per-user Git install flag (`/CURRENTUSER`) are untested on a real machine. Update this section after the first real run.
