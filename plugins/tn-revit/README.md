# tn-revit

Personal plugin of Claude skills for automating Revit tasks.

## Structure
- `skills/<skill-name>/SKILL.md` - one skill per folder
- `skills/_shared/` - shared rules, conventions and reviewed scripts (not a skill)
- `.claude-plugin/plugin.json` - plugin manifest

## Rules
- Naming: see `skills/_shared/naming-conventions.md`
- Safety and workflow: see `skills/_shared/safety-rules.md`

## Adding a new skill
1. Copy `skills/revit-audit-template/` and rename it (`revit-<verb>-<object>`).
2. Edit SKILL.md (name, description, workflow, rules).
3. Put reusable code in `skills/_shared/scripts/` after review.
4. Test on a detached sample model.
5. Update `CHANGELOG.md`, bump the version in `plugin.json`, commit and tag.

## Skills
| Skill | Type | Status |
|---|---|---|
| revit-audit-template | template | draft |
| revit-change-case | write | migrated, needs test on sample model |

## Versioning
Semantic versioning. Tag releases as `vX.Y.Z`.
