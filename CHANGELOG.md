# Changelog

## 0.5.0
- Add `install-markitdown-mcp` skill: installer script that sets up markitdown-mcp and registers it in Claude Desktop config (non-Revit setup skill).

## 0.4.0
- Add `revit-install-mcp` skill: installer script + guide for setting up Revit MCP (mcp-server-for-revit-python) on a new machine.
- Installer script installs Git and uv itself when winget is missing (asks Y/N first, `-Yes` to skip; Git installer SHA256-verified when published).
- Add `revit-install-*` verb prefix to naming conventions.

## 0.3.1
- Add `.claude-plugin/marketplace.json` so the repo can be installed from GitHub via `/plugin marketplace add`.

## 0.3.0
- Reorganize repo: repo root is now the plugin (`.claude-plugin/plugin.json`), shared rules moved to `docs/`, each skill self-contained.
- `revit-change-case` replaced with the safer version (script in the skill's `scripts/`).
- Add `templates/revit-audit-skill/` and `CLAUDE.md` maintainer rules.

## 0.2.0
- Add `revit-change-case` (migrated from standalone skill). Script at `scripts/change_case.py`.
- Script now uses a named transaction `TN: revit-change-case`, rollback on error, and a 200-change confirmation guard.

## 0.1.0
- Initial plugin scaffold: manifest, shared safety rules, naming conventions, audit skill template.
