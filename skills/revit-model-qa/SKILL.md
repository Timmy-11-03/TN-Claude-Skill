---
name: revit-model-qa
description: Quality-check a Revit model (BIM QA). Use when the user wants to review a model, check naming conventions for views/sheets/families, find empty parameters or warnings, or produce a QA report before handover. Triggers: "check the model", "Revit QA", "check naming", "review before submission".
---

# Revit Model QA

A review workflow for Revit models before handover. Always follow the steps below in order and present the results as a clear report.

## When to use
- The user asks to check or review a model, views, sheets, families or parameters.
- Before syncing, publishing or handing over a model.

## Workflow

1. **Confirm the scope**: which model, whole model or specific categories/levels. If unclear, ask one short question.
2. **Collect data** (if a Revit connector such as T3Lab MCP is available, use it; otherwise ask the user to export schedules or a CSV file):
   - Model info, list of levels, views and sheets
   - Family list by category
   - Values of key parameters
3. **Run the checks** (see `references/checklist.md`):
   - View/sheet names follow the naming convention
   - Views that are not placed on any sheet (unused views)
   - Required parameters that are empty
   - Duplicate or unused families
4. **Write the report** using the template below.

## Report template

| Check group | Issues | Severity | Notes |
|---|---|---|---|
| View naming | 0 | - | |

End the report with the **top 3 fixes to make first** and a suggested way to fix each.

## Notes
- Read and report only. Do not modify the model, delete elements or sync unless the user explicitly agrees.
- If data is missing, say which part could not be checked instead of guessing.
