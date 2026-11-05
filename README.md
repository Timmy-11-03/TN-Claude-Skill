# TN Claude

A personal skill toolkit for Claude, focused on BIM and Revit automation. Each skill is a folder in `skills/`. The repo is also a Claude Code plugin, and the source lives on GitHub so it can be used on multiple computers.

## Structure

```
TN-Claude-Skill/
├── .claude-plugin/plugin.json   # plugin manifest (name, version)
├── CLAUDE.md                    # maintainer rules, loaded by Claude Code
├── CHANGELOG.md
├── docs/
│   ├── naming-conventions.md    # how to name skills
│   └── safety-rules.md          # workflow and security rules for Revit skills
├── skills/                      # one self-contained folder per skill
│   ├── revit-change-case/
│   │   ├── SKILL.md
│   │   └── scripts/change_case.py
│   └── revit-model-qa/
│       ├── SKILL.md
│       └── references/checklist.md
├── templates/
│   ├── skill-template/          # generic skill template
│   └── revit-audit-skill/       # template for read-only Revit audit skills
└── scripts/build.py             # validate, package ZIPs, install
```

## Skills

| Skill | Type | Description |
|---|---|---|
| revit-change-case | write | Change case of sheet names, view names and text parameters |
| revit-model-qa | audit | BIM QA: naming, empty parameters, warnings, handover report |

## Common tasks

| Task | Command |
|---|---|
| Create a new skill | `python scripts/build.py new skill-name` |
| Validate all skills | `python scripts/build.py list` |
| Package ZIPs for claude.ai | `python scripts/build.py zip` |
| Install into Claude Code | `python scripts/build.py install` |

## Use as a plugin (Claude Code)

Install this repo as a plugin so all skills load together. Updating is `git pull`.

## Use on claude.ai / Claude Desktop

1. `python scripts/build.py zip`
2. Customize > Skills > "+" and upload a ZIP from `dist/` (one per skill).
3. Turn the skill on. "Code execution and file creation" must be enabled in Settings > Capabilities.

## Adding a new skill

1. `python scripts/build.py new revit-<verb>-<object>` (or copy `templates/revit-audit-skill/`)
2. Edit `skills/<name>/SKILL.md`; put code in the skill's `scripts/`
3. `python scripts/build.py list` to validate
4. Test on a detached sample model
5. Update `CHANGELOG.md`, bump the version in `.claude-plugin/plugin.json`
6. Work on a branch, open a Pull Request, merge to `main`
7. On another computer: `git pull`

## Conventions and security

- Naming: `docs/naming-conventions.md`
- Workflow and safety: `docs/safety-rules.md`
- Never put secrets, client data or model files in the repo.
