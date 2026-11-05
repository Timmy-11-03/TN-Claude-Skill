# Naming Conventions

Applies to every skill in `skills/`. Validate with `python scripts/build.py list`.

## Skill names
- Pattern: `revit-<verb>-<object>` in lowercase kebab-case, max 64 characters.
- The folder name must equal the `name` field in SKILL.md.
- One skill = one job. Chain jobs with an orchestrator skill (e.g. `revit-qa-pipeline`).
- Never include "claude" or "anthropic" in a name.

## Verb prefixes
| Prefix | Meaning | Writes to model? |
|---|---|---|
| `revit-audit-*` | Inspect and report | No |
| `revit-list-*` | Enumerate elements | No |
| `revit-set-*` / `revit-rename-*` / `revit-change-*` | Modify | Yes |
| `revit-export-*` | Output to file | No (writes files only) |
| `revit-qa-*` | Orchestrate several checks | Depends |

## Description rule
One or two sentences: what it does + when to use it, with trigger words in English and Vietnamese.

Example:
`Rename Revit sheets by a pattern. Use when asked to rename, renumber or normalize sheet names / đổi tên sheet.`
