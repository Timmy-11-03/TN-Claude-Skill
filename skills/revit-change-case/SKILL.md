---
name: revit-change-case
description: Change text case (UPPER, lower, Title Case, Capitalize) of Revit sheet names, view names or any text parameter via Revit-Connector execute_revit_code. Use when asked to change/normalize case in Revit.
---

# Revit: change text case

Changes the case of text in the open Revit model using the Revit-Connector `execute_revit_code` tool (IronPython, `doc` and `DB` are provided, no transaction is opened automatically).

## Case modes

| Mode | Result for `first floor PLAN` |
|---|---|
| `upper` | `FIRST FLOOR PLAN` |
| `lower` | `first floor plan` |
| `title` | `First Floor Plan` |
| `capitalize` | `First floor plan` (first letter upper, rest lower) |

## Targets

| Target | What is changed |
|---|---|
| `sheet_names` | `ViewSheet.Name` (SheetNumber is not touched) |
| `sheet_numbers` | `ViewSheet.SheetNumber` (only if explicitly requested) |
| `view_names` | `View.Name` of all non-template, non-sheet views (plans, sections, elevations, 3D, drafting, schedules) |
| `view_templates` | `View.Name` of view templates (only if explicitly requested) |
| `text_params` | Any text (String) parameter(s) by name on a category or on the current selection (e.g. Room Name, Mark, Comments, a type parameter) |

## Prerequisites

1. Load Revit-Connector tools with ToolSearch (`get_revit_status`, `execute_revit_code`, optionally `get_revit_model_info`, `list_category_parameters`).
2. Call `get_revit_status` and confirm Status active, Health healthy, API revit_mcp.
   - `RouteHandlerNotDefinedException` for `revit_mcp/...` means the revit_mcp extension is not loaded: ask the user to pyRevit > Reload (or restart Revit) and retry.

## Workflow

1. Work out three things: the mode, the target(s), and for `text_params` the category and parameter name(s). If any is unclear, ask with AskUserQuestion; never guess on a model-modifying action.
2. For `text_params`, use `list_category_parameters` to confirm the exact parameter name and that it is a text parameter.
3. Run the code below first with `DRY_RUN = True` to preview (nothing is changed). For large scopes (all views, all elements of a category) always preview first and show counts and a few examples. For a small, explicit request (e.g. all sheet names to upper) the user's request is the approval and you may run with `DRY_RUN = False` directly.
4. Run with `DRY_RUN = False` to apply, then report.
5. If the user rejects a code execution, stop and ask how to proceed; do not retry the same code.

## Code (edit the CONFIG block, then run with execute_revit_code)

```python
import re

# ---------------- CONFIG ----------------
MODE = "upper"            # upper | lower | title | capitalize
TARGETS = ["sheet_names"]  # sheet_names | sheet_numbers | view_names | view_templates | text_params
TEXT_PARAM_CATEGORY = None  # e.g. DB.BuiltInCategory.OST_Rooms  (for text_params)
TEXT_PARAM_NAMES = []       # e.g. ["Name", "Comments"]
USE_SELECTION = False       # True = text_params applies to the current selection instead of a category
INCLUDE_TYPES = False       # True = also process the element TYPE of each element for text_params
DRY_RUN = True              # True = preview only, nothing modified
# ----------------------------------------

def to_title(s):
    return re.sub(r"(^|[\s/\-\(\[_.])(\S)", lambda m: m.group(1) + m.group(2).upper(), s.lower())

def change_case(s):
    if s is None:
        return s
    if MODE == "upper":
        return s.upper()
    if MODE == "lower":
        return s.lower()
    if MODE == "title":
        return to_title(s)
    if MODE == "capitalize":
        return s[:1].upper() + s[1:].lower()
    raise ValueError("Unknown MODE: " + MODE)

changes = []   # (label, old, new, setter)
skipped = []

def queue(label, old, setter):
    new = change_case(old)
    if new != old:
        changes.append((label, old, new, setter))

def prop_setter(el, prop):
    return lambda v: setattr(el, prop, v)

def param_setter(p):
    return lambda v: p.Set(v)

if "sheet_names" in TARGETS or "sheet_numbers" in TARGETS:
    for s in DB.FilteredElementCollector(doc).OfClass(DB.ViewSheet):
        if "sheet_names" in TARGETS:
            queue("Sheet " + s.SheetNumber, s.Name, prop_setter(s, "Name"))
        if "sheet_numbers" in TARGETS:
            queue("SheetNumber", s.SheetNumber, prop_setter(s, "SheetNumber"))

if "view_names" in TARGETS or "view_templates" in TARGETS:
    skip_types = (DB.ViewType.ProjectBrowser, DB.ViewType.SystemBrowser, DB.ViewType.Internal)
    for v in DB.FilteredElementCollector(doc).OfClass(DB.View):
        if isinstance(v, DB.ViewSheet) or v.ViewType in skip_types:
            continue
        if v.IsTemplate and "view_templates" not in TARGETS:
            continue
        if (not v.IsTemplate) and "view_names" not in TARGETS:
            continue
        queue("View", v.Name, prop_setter(v, "Name"))

if "text_params" in TARGETS:
    if USE_SELECTION:
        els = [doc.GetElement(i) for i in uidoc.Selection.GetElementIds()]
    else:
        els = list(DB.FilteredElementCollector(doc).OfCategory(TEXT_PARAM_CATEGORY).WhereElementIsNotElementType())
    seen = set()
    for e in els:
        pool = [e]
        if INCLUDE_TYPES:
            t = doc.GetElement(e.GetTypeId())
            if t is not None and t.Id.IntegerValue not in seen:
                seen.add(t.Id.IntegerValue)
                pool.append(t)
        for el in pool:
            for pn in TEXT_PARAM_NAMES:
                p = el.LookupParameter(pn)
                if p is None or p.StorageType != DB.StorageType.String or p.IsReadOnly:
                    skipped.append((str(el.Id.IntegerValue), pn, "missing / not text / read-only"))
                    continue
                val = p.AsString()
                if val:
                    queue("%s [%s]" % (el.Id.IntegerValue, pn), val, param_setter(p))

applied = 0
if not DRY_RUN and changes:
    t = DB.Transaction(doc, "Change case: " + MODE)
    t.Start()
    for label, old, new, setter in changes:
        try:
            setter(new)
            applied += 1
        except Exception as ex:
            skipped.append((label, old, str(ex)))
    t.Commit()

print("MODE=%s TARGETS=%s DRY_RUN=%s" % (MODE, TARGETS, DRY_RUN))
print("To change: %d | Applied: %d | Skipped: %d" % (len(changes), applied, len(skipped)))
for label, old, new, _ in changes[:200]:
    print("%s: %s -> %s" % (label, old, new))
for s in skipped[:50]:
    print("SKIPPED %s" % (s,))
```

## Examples

- All sheet names to UPPER: `MODE="upper"`, `TARGETS=["sheet_names"]`.
- All view names to Title Case: `MODE="title"`, `TARGETS=["view_names"]`.
- Sheets and views to lowercase: `MODE="lower"`, `TARGETS=["sheet_names","view_names"]`.
- Room names to Capitalize: `MODE="capitalize"`, `TARGETS=["text_params"]`, `TEXT_PARAM_CATEGORY=DB.BuiltInCategory.OST_Rooms`, `TEXT_PARAM_NAMES=["Name"]`.
- Comments on the current selection to UPPER: `TARGETS=["text_params"]`, `USE_SELECTION=True`, `TEXT_PARAM_NAMES=["Comments"]`.

## Gotchas

- `System` is not defined in this tool's namespace; use `from System.Collections.Generic import List` style imports if .NET types are needed.
- Names of views and sheets must be unique. A case-only rename that collides, or a view that Revit refuses to rename, lands in the skipped list with the error message; the rest still apply.
- `title` lowercases everything first, so acronyms and codes become e.g. `Hvac`, `3d`. Mention this, and offer to skip or fix specific items.
- Non-ASCII letters (e.g. Café) are handled by the string methods.
- Read-only parameters (built-in or formula/shared-locked) cannot be changed and are reported as skipped.
- Changing `view_names` can affect schedules, tags and sheet viewport titles that display the name; warn the user when applying to all views.
- Changes are made in the open document only and are NOT saved. Tell the user they can undo with Ctrl+Z, and offer `save_document` if wanted.

## Report back

Short summary: mode, targets, changed vs skipped counts, two or three examples, that sheet numbers (unless targeted) are unchanged, and that the model is unsaved.
