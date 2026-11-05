---
name: revit-audit-template
description: Template for a read-only Revit audit skill. Copy this folder, rename it to revit-audit-<object>, and edit. Use when creating a new audit skill / tạo skill kiểm tra mới.
---

# Revit Audit Template

Read `docs/safety-rules.md` and `docs/naming-conventions.md` in the repo before using or editing this skill.

## Purpose
Describe in one sentence what this skill inspects (e.g. "Report views not placed on any sheet").

## When to use
- Trigger phrase 1
- Trigger phrase 2

## Inputs
- Scope: active view / whole model / selected category
- Optional filters

## Workflow
1. **Pre-check**: call `get_revit_status` and `get_revit_model_info`; confirm file and Revit version.
2. **Collect**: gather elements using `execute_revit_code` or the dedicated Revit-Connector tools.
3. **Analyze**: apply the rule(s) described below.
4. **Report**: output a table (element id, name, issue, suggested fix) and a count summary.

## Rules checked
- Rule A: ...
- Rule B: ...

## Does NOT do
- Does not modify the model.
- Does not save or sync.

## Output format
Markdown table plus a one-line summary: `N issues found in M elements`.

## Tested on
- Revit version(s): (fill in)
- Date: (fill in)
