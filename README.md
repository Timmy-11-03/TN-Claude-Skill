# TN Claude

A personal skill toolkit for Claude. Each skill is a folder inside `skills/`, and the source lives on GitHub so it can be used on multiple computers.

## Structure

```
TN-Claude/
├── skills/                    # one folder per skill
│   └── revit-model-qa/
│       ├── SKILL.md           # required
│       └── references/        # optional: long docs, checklists
├── templates/skill-template/  # template for new skills
├── scripts/build.py           # validate, package ZIPs, install
└── dist/                      # generated ZIPs (not committed to git)
```

## Common tasks

| Task | Command |
|---|---|
| Create a new skill from the template | `python scripts/build.py new skill-name` |
| Validate all skills | `python scripts/build.py list` |
| Package ZIPs for claude.ai | `python scripts/build.py zip` |
| Install into Claude Code | `python scripts/build.py install` |

## Use on claude.ai / Claude Desktop

1. `python scripts/build.py zip`
2. Go to Customize > Skills > "+" and upload a file from `dist/` (one ZIP per skill).
3. Turn the skill on. "Code execution and file creation" must be enabled in Settings > Capabilities.

## Use in Claude Code

`python scripts/build.py install` copies the skills into `~/.claude/skills/`.

## Adding a new skill (workflow)

1. `python scripts/build.py new skill-name`
2. Edit `skills/skill-name/SKILL.md`
3. `python scripts/build.py list` to validate
4. `git add . && git commit -m "Add skill-name" && git push`
5. On another computer: `git pull`, then zip/upload or install again

## Conventions
- Skill names: lowercase letters, digits and hyphens; must match the folder name.
- One skill, one job. The `description` must say when to use it.
- Never put secrets (API keys, passwords, client data) in a skill.
