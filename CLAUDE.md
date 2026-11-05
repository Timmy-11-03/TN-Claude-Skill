# TN Claude - maintainer rules

This repo is both a skill toolkit (zip/install via `scripts/build.py`) and a Claude Code plugin (`.claude-plugin/plugin.json` + `skills/`).

## Rules when creating or editing a skill
- Create with `python scripts/build.py new <skill-name>`; for Revit audit skills copy `templates/revit-audit-skill/`.
- Naming: follow `docs/naming-conventions.md` (`revit-<verb>-<object>`, folder name = `name`).
- Any skill that writes to a model must follow `docs/safety-rules.md` (pre-check, dry-run, confirm, named transaction, post-check). Never save or sync automatically.
- Each skill must be self-contained: code in the skill's `scripts/`, long docs in its `references/`. No `../` paths.
- Write all repo content in English.
- Never commit secrets, client names, or Revit/Navisworks files.
- Before committing: `python scripts/build.py list` must show OK for every skill. Update `CHANGELOG.md` and bump the version in `.claude-plugin/plugin.json`.
- Test write skills on a detached copy of a sample model.
