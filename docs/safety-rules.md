# Safety Rules for All Revit Skills

These rules apply to every skill in this plugin. Each SKILL.md must reference this file.

## 1. Scope and permissions
- Default to read-only. A skill that writes to the model must say so in its description.
- Never run `save_document` or `sync_with_central` automatically. The user decides.
- Never modify elements owned by another user (check workset ownership first).
- Never delete elements in bulk. If deletion is required, list the elements and ask for explicit confirmation per batch.

## 2. Standard workflow for write skills
1. **Pre-check**: `get_revit_status`, `get_revit_model_info`. Confirm the correct file, Revit version and active view.
2. **Read-only scan**: count and list the affected elements.
3. **Dry-run**: show a before/after table. Write nothing.
4. **Confirm**: wait for the user's approval. If affected elements > 200, ask again with the exact count.
5. **Execute**: one named Transaction (`TN: <skill-name>`), wrapped in try/except with rollback on error.
6. **Post-check**: re-count, compare with the scan, report differences and any skipped elements.

## 3. Code restrictions (execute_revit_code)
Do not generate or run code that:
- calls `os.system`, `subprocess`, `eval`, `exec`, or spawns processes
- makes network requests
- reads or writes files outside the project output folder
- accesses credentials, tokens or environment secrets

Reusable code lives in the skill's own `scripts/` folder and is reviewed before use. Prefer it over ad-hoc code. Each skill must be self-contained (no `../` references), because skills are zipped and installed one by one.

## 4. Secrets and data
- No tokens, passwords, internal server paths or client names in any skill file.
- Local configuration goes in `config.local.json` (git-ignored).
- Never commit `.rvt`, `.rfa`, `.nwc` or exported client data.

## 5. Testing
- Test new or changed skills on a detached copy of a sample model first.
- Record the Revit versions tested in the skill's frontmatter or CHANGELOG.

## 6. Logging
Every write skill ends with a short log: what changed, how many elements, what was skipped and why.
