# Automated Revit MCP Install on Another Machine

Use this guide to install `mcp-server-for-revit-python` for Claude on a new machine (home, office, a colleague's PC). The installer script `install-revit-mcp.ps1` does most of the work; this guide covers what to prepare first and what to do when something is missing.

---

## 1. Quick start (TL;DR)

1. Install Revit, pyRevit and Claude Desktop (section 2). **Git** and **uv** are installed by the script if they are missing; it asks you to approve first.
2. Get **only the one file** `install-revit-mcp.ps1` onto the new machine: copy it (USB drive, OneDrive), or open the private GitHub repo in a browser where you are signed in, go to `skills/revit-install-mcp/scripts/`, and use the **Download raw file** button. Nothing else is needed: the script installs Git and uv itself. (The repo is private, so a plain download link without sign-in will not work.)
3. **Close Revit and Claude Desktop.**
4. Open a **new** PowerShell (as Administrator if you want the firewall rule) and run:

```powershell
powershell -ExecutionPolicy Bypass -File "C:\path\to\install-revit-mcp.ps1" -UseMaster
```

5. Fully restart Revit and Claude Desktop (section 5), then ask Claude: *"Check the Revit connection status."*

If the script stops with an error, find it in the troubleshooting table (section 8).

---

## 2. Prerequisites

| Item | Required | Notes |
|---|---|---|
| Windows 10/11 | Yes | The script is PowerShell for Windows only |
| Revit | Yes | Already working. Original machine: Revit 2024.3. The script only warns if it finds no Revit under `C:\Program Files\Autodesk` |
| pyRevit | Yes | Installed, and **Revit opened at least once** (this creates `%APPDATA%\pyRevit`). Original machine: pyRevit 6.5.2. Make sure your pyRevit version supports your Revit version |
| Claude Desktop | Yes | Installed and signed in |
| Git | Yes | Installed by the script after you approve (winget if available, otherwise the official Git for Windows installer from GitHub). Manual install is the fallback (see 2.1) |
| uv (Python manager) | Yes | Installed by the script after you approve (winget if available, otherwise the official installer from astral.sh). Manual install is the fallback (see 2.2) |
| Internet | Yes | Access to GitHub, PyPI, python.org downloads (used by `uv`), and astral.sh. Corporate networks may block these |

The script itself installs Python 3.13 and all Python dependencies through `uv`, so you do **not** need to install Python yourself.

### 2.0 Check what you already have

Open PowerShell and run:

```powershell
winget --version     # if "not recognized": you have no winget, install Git and uv manually
git --version        # should print a version number
uv --version         # should print a version number
```

### 2.1 Install Git manually (fallback, if the script cannot install it)

1. Download "64-bit Git for Windows Setup" from https://git-scm.com/download/win
2. Run the installer and accept all default options.
3. **Close PowerShell and open a new one.** An already-open window does not see the updated PATH.
4. Check: `git --version`

Shortcut if `git` is still not recognized in an already-open window (this fix lasts only for that window):

```powershell
$env:Path += ";C:\Program Files\Git\cmd"
git --version
```

### 2.2 Install uv manually (fallback, if the script cannot install it)

Run this in PowerShell. Keep `-ExecutionPolicy Bypass`: without it, the installer refuses to run with the message *"PowerShell requires an execution policy in [Unrestricted, RemoteSigned, Bypass] to run uv"*.

```powershell
powershell -ExecutionPolicy Bypass -c "irm https://astral.sh/uv/install.ps1 | iex"
```

`uv.exe` is placed in `%USERPROFILE%\.local\bin`, and the script looks for it there. If the script still cannot find `uv`, close PowerShell, open a new one, and run the script again. Check: `uv --version`

---

## 3. How to run the script

1. Copy `install-revit-mcp.ps1` to the new machine (USB drive, OneDrive, etc.).
2. **Close Revit and Claude Desktop.**
3. Open a **new** PowerShell window and run (keep the quotes if the path has spaces):

```powershell
powershell -ExecutionPolicy Bypass -File "path\to\install-revit-mcp.ps1" -UseMaster
```

To let the script create the firewall rule as well, open PowerShell with **Run as administrator**. Without admin rights the script only prints the command for you to run later.

The script is safe to run more than once.

---

## 4. What the script does (8 steps)

1. Checks pyRevit, Revit and Git. If Git is missing it asks `Install Git for Windows now? (Y/N)`, then tries winget, and if winget is missing or fails, downloads the official installer from the `git-for-windows` GitHub release, verifies its SHA256 when GitHub publishes one, and installs it silently (per-user when not Administrator).
2. Finds `uv.exe`. If missing it asks for approval, then installs it with winget, or with the official installer from `https://astral.sh/uv/install.ps1` when winget is missing or fails.
3. Clones the extension into `%APPDATA%\pyRevit\Extensions\mcp-server-for-revit-python.extension` and checks out the right version.
4. Installs Python 3.13 and the dependencies (`uv sync --frozen`), with a retry on failure.
5. Verifies that `main.py` imports correctly.
6. Sets `[routes] enabled = true` in `pyRevit_config.ini` (a `.bak` backup is made).
7. Adds the `Revit-Connector` server to `claude_desktop_config.json` (other servers are kept, a `.bak` backup is made) and to Claude Code if the `claude` CLI is present. All paths are computed from the current user's profile, so never copy a `claude_desktop_config` file from another machine.
8. Creates a firewall rule that blocks inbound access to port 48884 from other machines.

The original console messages are in unaccented Vietnamese; the messages added for the Git / uv fallback are in English. Quick translation:

| Message | Meaning |
|---|---|
| `Kiem tra moi truong` | Checking environment |
| `Chua co Git` / `Khong co winget` | Git not installed / winget not available |
| `Cai thu cong` | Install manually |
| `LOI` / `[!]` / `[OK]` | Error / warning / success |
| `HOAN TAT` | Done |

---

## 5. After the script finishes

1. **Fully close Revit**, reopen it, and open a model. Do not use *Reload pyRevit*, because it can hang the Routes server.
2. **Fully quit Claude Desktop** (right-click the system tray icon → Quit), then reopen it.
3. If you installed with `-UseMaster`: in Revit click **MCP > Bridge > Connect** and confirm **Yes**. This creates the pairing for your Windows user.
4. Start a **new chat** in Claude Desktop and ask: *"Check the Revit connection status."* The correct result is `active / healthy`.

Optional manual check (after Revit has a model open):

```powershell
cd "$env:APPDATA\pyRevit\Extensions\mcp-server-for-revit-python.extension"
uv run --frozen python -c "import anyio; from main import revit_get; print(anyio.run(revit_get, '/status/'))"
```

---

## 6. Script options

| Option | Effect |
|---|---|
| `-Ref <commit>` | Use a different commit or branch (default `4e8ec5f`) |
| `-UseMaster` | Use the latest version with authentication and an approval prompt inside Revit. **Only use this if pyRevit on that machine forwards HTTP headers**, otherwise you will get the 408 error (see section 8) |
| `-ServerName <name>` | Change the server name shown in Claude (default `Revit-Connector`) |
| `-SkipFirewall` | Do not create the firewall rule |
| `-SkipRoutes` | Do not edit `pyRevit_config.ini` (enable Routes yourself: pyRevit tab > Settings > Routes) |
| `-Yes` | Do not ask for confirmation before installing Git / uv (for unattended runs; by default the script asks Y/N) |

Example: `.\install-revit-mcp.ps1 -UseMaster -SkipFirewall`

---

## 7. Choosing the extension version

| Version | How | Pros | Cons |
|---|---|---|---|
| Latest (`master`) | `-UseMaster` | Authentication; Revit shows a review prompt before model changes and Python execution | Needs a pyRevit that forwards HTTP headers; may give the 408 error on pyRevit 6.5.2 |
| Pre-pairing (`4e8ec5f`) | default | Works with pyRevit 6.5.2 | **No authentication and no approval prompt inside Revit** when modifying the model or running code |

Recommendation: try `-UseMaster` first. If you get the 408 error, run the script again without `-UseMaster`.

Note: switching versions changes the files in the extension folder. Do not keep local edits in that folder, because switching can fail or overwrite them. Keep your own changes in a separate repository.

---

## 8. Troubleshooting

| Symptom | Fix |
|---|---|
| `Chua cai pyRevit` (pyRevit not installed) | Install pyRevit, open Revit once, run the script again |
| `git : The term 'git' is not recognized` | Git is not installed, or the PowerShell window is older than the Git install. Install Git (2.1), then open a **new** PowerShell |
| `Khong cai duoc Git` (could not install Git) | Both winget and the direct download failed (network/proxy blocks `api.github.com` or `github.com`, or the installer was cancelled). Install Git manually (2.1), open a new PowerShell, run the script again |
| `SHA256 mismatch` | The downloaded Git installer was deleted. Run again; if it repeats, install Git manually (2.1) |
| `Khong co winget` (no winget) | Only seen with an older copy of the script. Use the current script (it falls back to the official installers) or install `uv` manually (2.2) |
| `PowerShell requires an execution policy ... to run uv` | Run the uv installer with `-ExecutionPolicy Bypass` (2.2) |
| `Khong tim thay uv sau khi cai` (uv not found after install) | Close PowerShell, open a new one, run the script again |
| `git clone that bai` (git clone failed) | Corporate network or proxy is blocking GitHub. Ask IT to allow it, or clone manually |
| `... da ton tai nhung khong phai repo git` (folder exists but is not a git repo) | Rename or delete `mcp-server-for-revit-python.extension` in `%APPDATA%\pyRevit\Extensions`, then run again |
| `uv sync that bai` (uv sync failed) | Close Revit and Claude. If `.venv` is locked, rename it to `.venv-old` and run again |
| `Revit-Connector` does not appear in Claude | Claude Desktop was not fully quit (use the tray icon → Quit). Check `claude_desktop_config.json` (the script writes to `%APPDATA%\Claude\` and also to the Microsoft Store location if that exists) |
| `All connection attempts failed` | No model open in Revit, Routes not enabled, or wait about 30 seconds after Revit starts |
| Constant timeouts | Routes server is hung → restart Revit |
| `408 ... 'NoneType' ... 'ToString'` | Running the `master` version on pyRevit 6.5.2 → run the script again without `-UseMaster` |

---

## 9. Undo / rollback

- **Disconnect Claude from Revit:** in Revit click **MCP > Bridge > Disconnect** (master version only).
- **Remove the server from Claude Desktop:** delete the `Revit-Connector` block from `claude_desktop_config.json`, or restore the `.bak` copy the script made next to it. Then fully quit and reopen Claude Desktop.
- **Remove from Claude Code:** `claude mcp remove -s user Revit-Connector`
- **Turn off Routes:** restore `pyRevit_config.ini.bak`, or disable Routes in pyRevit Settings.
- **Remove the firewall rule** (Administrator): `Remove-NetFirewallRule -DisplayName "Block pyRevit Routes 48884 inbound"`
- **Remove the extension:** delete the folder `%APPDATA%\pyRevit\Extensions\mcp-server-for-revit-python.extension`.

---

## 10. Notes for use at work

- Ask IT first. The pre-pairing version has no authentication and can run code inside Revit.
- Project names, parameters and view images are sent to Claude. Check your company's and clients' confidentiality rules.
- Try changes on a copy of the model before letting Claude edit the real one.
- Never save, sync with central, or close a document through Claude without reviewing it first.
