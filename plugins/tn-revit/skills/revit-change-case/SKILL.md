---
name: revit-change-case
description: Change text case (UPPER, lower, Title Case, Capitalize) of Revit sheet names, view names, view templates or any text parameter via Revit-Connector. Use when asked to change/normalize case in Revit / đổi chữ hoa, chữ thường, viết hoa tên sheet, view.
---

# Revit: Change Text Case

Type: **write skill**. Read `../_shared/safety-rules.md` first and follow its 6-step workflow.
Runs `../_shared/scripts/change_case.py` through the Revit-Connector `execute_revit_code` tool (IronPython; `doc`, `uidoc`, `DB` are provided; no transaction is opened automatically).

## Case modes

| Mode | Result for `first floor PLAN` |
|---|---|
| `upper` | `FIRST FLOOR PLAN` |
| `lower` | `first floor plan` |
| `title` | `First Floor Plan` |
| `capitalize` | `First floor plan` |

## Targets

| Target | What changes |
|---|---|
| `sheet_names` | `ViewSheet.Name` (SheetNumber untouched) |
| `sheet_numbers` | `ViewSheet.SheetNumber` (only if explicitly requested) |
| `view_names` | `View.Name` of non-template, non-sheet views |
| `view_templates` | `View.Name` of view templates (only if explicitly requested) |
| `text_params` | Named text parameter(s) on a category or on the current selection |

## Workflow (maps to safety-rules.md)

1. **Pre-check**: load Revit-Connector tools (ToolSearch), call `get_revit_status` (Status active, Health healthy, API revit_mcp) and `get_revit_model_info`. If `RouteHandlerNotDefinedException` for `revit_mcp/...` appears, ask the user to pyRevit > Reload or restart Revit.
2. **Clarify**: confirm mode, target(s) and, for `text_params`, category and parameter name(s) (use `list_category_parameters`). Never guess on a model-modifying action; ask if unclear.
3. **Scan + dry-run**: edit the CONFIG block of the script, run with `DRY_RUN = True`. Show counts and examples.
4. **Confirm**: wait for approval. If changes > 200, re-confirm the exact count, then set `CONFIRMED_LARGE = True`.
5. **Execute**: run with `DRY_RUN = False` (one Transaction named `TN: revit-change-case (<mode>)`, rollback on error).
6. **Post-check and report**: mode, targets, changed vs skipped counts, 2-3 examples, note that sheet numbers are unchanged (unless targeted) and the model is unsaved.

If the user rejects a code execution, stop and ask how to proceed; do not retry the same code.

## Examples

- All sheet names to UPPER: `MODE="upper"`, `TARGETS=["sheet_names"]`.
- All view names to Title Case: `MODE="title"`, `TARGETS=["view_names"]`.
- Room names to Capitalize: `MODE="capitalize"`, `TARGETS=["text_params"]`, `TEXT_PARAM_CATEGORY=DB.BuiltInCategory.OST_Rooms`, `TEXT_PARAM_NAMES=["Name"]`.
- Comments on current selection to UPPER: `TARGETS=["text_params"]`, `USE_SELECTION=True`, `TEXT_PARAM_NAMES=["Comments"]`.

## Gotchas

- Sheet and view names must be unique. Collisions or refused renames go to the skipped list; the rest still apply.
- `title` lowercases everything first, so acronyms become `Hvac`, `3d`. Warn the user and offer to fix specific items.
- Read-only parameters cannot be changed and are reported as skipped.
- Renaming views can affect schedules, tags and viewport titles that show the name; warn before applying to all views.
- `System` is not defined in the tool namespace; import .NET types explicitly if needed.

## Does NOT do

- Does not save or sync. Changes live in the open document only; tell the user they can undo with Ctrl+Z, and offer `save_document` only if they ask.
- Does not touch sheet numbers or view templates unless explicitly targeted.

## Tested on

- Revit version(s): (fill in)
- Date: (fill in)
