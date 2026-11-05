#!/usr/bin/env python3
"""TN Claude - skill packaging and installation tool.

Usage (run from the repo root):
    python scripts/build.py list                 # list skills and validate SKILL.md
    python scripts/build.py zip                  # create dist/<skill>.zip for upload to claude.ai
    python scripts/build.py zip revit-model-qa   # package a single skill
    python scripts/build.py install              # copy all skills into ~/.claude/skills (Claude Code)
    python scripts/build.py install revit-model-qa
    python scripts/build.py new my-new-skill     # create a new skill from the template
"""
import re
import shutil
import sys
import zipfile
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SKILLS = ROOT / "skills"
DIST = ROOT / "dist"
TEMPLATE = ROOT / "templates" / "skill-template"
CLAUDE_SKILLS = Path.home() / ".claude" / "skills"
NAME_RE = re.compile(r"^[a-z0-9]+(-[a-z0-9]+)*$")


def skill_dirs(names):
    all_dirs = sorted(p for p in SKILLS.iterdir() if p.is_dir() and not p.name.startswith((".", "_")))
    if not names:
        return all_dirs
    picked = [p for p in all_dirs if p.name in names]
    missing = set(names) - {p.name for p in picked}
    if missing:
        sys.exit(f"Skill not found: {', '.join(sorted(missing))}")
    return picked


def validate(skill):
    """Return a list of errors for one skill."""
    errors = []
    md = skill / "SKILL.md"
    if not md.exists():
        return ["missing SKILL.md"]
    text = md.read_text(encoding="utf-8")
    m = re.match(r"^---\r?\n(.*?)\r?\n---", text, re.S)
    if not m:
        return ["SKILL.md is missing the frontmatter block (--- ... ---)"]
    fm = m.group(1)
    name = re.search(r"^name:\s*(.+)$", fm, re.M)
    desc = re.search(r"^description:\s*(.+)$", fm, re.M)
    if not name:
        errors.append("frontmatter is missing 'name'")
    else:
        n = name.group(1).strip()
        if not NAME_RE.match(n):
            errors.append(f"name '{n}' must use lowercase letters, digits and hyphens")
        if n != skill.name:
            errors.append(f"name '{n}' does not match folder name '{skill.name}'")
    if not desc:
        errors.append("frontmatter is missing 'description'")
    elif len(desc.group(1).strip()) > 1024:
        errors.append("description is longer than 1024 characters")
    return errors


def cmd_list(names):
    ok = True
    for s in skill_dirs(names):
        errs = validate(s)
        print(("OK    " if not errs else "ERROR ") + s.name)
        for e in errs:
            print("      - " + e)
        ok = ok and not errs
    return 0 if ok else 1


def cmd_zip(names):
    DIST.mkdir(exist_ok=True)
    for s in skill_dirs(names):
        errs = validate(s)
        if errs:
            sys.exit(f"Skipping {s.name}: " + "; ".join(errs))
        out = DIST / f"{s.name}.zip"
        with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
            for f in sorted(s.rglob("*")):
                if f.is_file():
                    z.write(f, f.relative_to(s).as_posix())  # SKILL.md sits at the ZIP root
        print(f"Created {out.relative_to(ROOT)}")
    return 0


def cmd_install(names):
    CLAUDE_SKILLS.mkdir(parents=True, exist_ok=True)
    for s in skill_dirs(names):
        errs = validate(s)
        if errs:
            sys.exit(f"Skipping {s.name}: " + "; ".join(errs))
        dest = CLAUDE_SKILLS / s.name
        if dest.exists():
            shutil.rmtree(dest)
        shutil.copytree(s, dest)
        print(f"Installed {s.name} -> {dest}")
    return 0


def cmd_new(names):
    if len(names) != 1 or not NAME_RE.match(names[0]):
        sys.exit("Usage: python scripts/build.py new skill-name (lowercase, hyphens)")
    dest = SKILLS / names[0]
    if dest.exists():
        sys.exit(f"{names[0]} already exists")
    shutil.copytree(TEMPLATE, dest)
    md = dest / "SKILL.md"
    md.write_text(md.read_text(encoding="utf-8").replace("skill-name-lowercase-with-hyphens", names[0]), encoding="utf-8")
    print(f"Created {dest.relative_to(ROOT)}/SKILL.md - open it and edit the content.")
    return 0


COMMANDS = {"list": cmd_list, "zip": cmd_zip, "install": cmd_install, "new": cmd_new}

if __name__ == "__main__":
    if len(sys.argv) < 2 or sys.argv[1] not in COMMANDS:
        print(__doc__)
        sys.exit(1)
    sys.exit(COMMANDS[sys.argv[1]](sys.argv[2:]))
