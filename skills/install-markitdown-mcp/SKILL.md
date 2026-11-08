---
name: install-markitdown-mcp
description: Install markitdown-mcp on a Windows machine and register it in Claude Desktop config. Use when setting up MCP on a new computer, or asked to install, reinstall or connect markitdown / cài markitdown MCP, cài trên máy mới.
---

# Install markitdown-mcp

Type: **setup skill** (changes the user's machine and Claude config, never a Revit model). Follows `docs/safety-rules.md` sections 1 and 4: nothing is changed without the user's confirmation, and no secrets are written anywhere.

Bundled file: `scripts/install-markitdown-mcp.ps1` - installs Python if missing, `pip install markitdown-mcp`, merges a `markitdown` entry into `claude_desktop_config.json`. Safe to re-run.

## When to use
- Setting up markitdown MCP on a new or second machine.
- `markitdown` is missing from Claude Desktop's MCP servers after a reinstall.

## Workflow
1. **Pre-check (read-only).** Windows? `python --version`, `winget --version`. Is Claude Desktop installed?
2. **Preview, then confirm.** Tell the user what the script changes: install Python 3.12 via winget if missing, `pip install --upgrade markitdown-mcp`, add `markitdown` to `%APPDATA%\Claude\claude_desktop_config.json` (`.bak` kept, other servers kept). Wait for approval.
3. **Run** on the user's own PowerShell (close Claude Desktop first):
   `powershell -ExecutionPolicy Bypass -File "<path>\install-markitdown-mcp.ps1"`
4. **After install.** Fully quit and reopen Claude Desktop, start a new chat.
5. **Verify.** The script prints the executable path; check `mcpServers.markitdown` exists in the config and the tool is listed in a new chat. Report what was and was not verified.

## Expected output
Short report: what was installed, config path and backup, verification result, remaining manual steps.

## Notes
- Never run the script from a cloud workspace for the user's machine; it must run on the user's own PowerShell.
- Never overwrite the config; only merge. The `.bak` copy is the rollback.
- If Python was just installed and is not on PATH, open a new terminal and re-run.
- Does NOT touch any Revit document.

## Tested on
- Verified: package `markitdown-mcp` exists on PyPI and its console script is `markitdown-mcp`.
- NOT yet run: the PowerShell script has not been executed or syntax-checked on a real machine. Update this section after the first real run.
