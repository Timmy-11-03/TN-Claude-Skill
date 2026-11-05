import re

# ---------------- CONFIG ----------------
MODE = "upper"             # upper | lower | title | capitalize
TARGETS = ["sheet_names"]  # sheet_names | sheet_numbers | view_names | view_templates | text_params
TEXT_PARAM_CATEGORY = None # e.g. DB.BuiltInCategory.OST_Rooms  (for text_params)
TEXT_PARAM_NAMES = []      # e.g. ["Name", "Comments"]
USE_SELECTION = False      # True = text_params applies to the current selection instead of a category
INCLUDE_TYPES = False      # True = also process the element TYPE of each element for text_params
DRY_RUN = True             # True = preview only, nothing modified
LARGE_THRESHOLD = 200      # above this many changes, require CONFIRMED_LARGE = True
CONFIRMED_LARGE = False    # set True only after the user re-confirms the exact count
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
blocked = False
if not DRY_RUN and len(changes) > LARGE_THRESHOLD and not CONFIRMED_LARGE:
    blocked = True   # safety rule: large batches need explicit re-confirmation

if not DRY_RUN and changes and not blocked:
    t = DB.Transaction(doc, "TN: revit-change-case (" + MODE + ")")
    t.Start()
    try:
        for label, old, new, setter in changes:
            try:
                setter(new)
                applied += 1
            except Exception as ex:
                skipped.append((label, old, str(ex)))
        t.Commit()
    except Exception as ex:
        t.RollBack()
        skipped.append(("TRANSACTION", "", "rolled back: " + str(ex)))
        applied = 0

print("MODE=%s TARGETS=%s DRY_RUN=%s" % (MODE, TARGETS, DRY_RUN))
if blocked:
    print("BLOCKED: %d changes exceed threshold %d. Re-confirm the count with the user, then set CONFIRMED_LARGE = True." % (len(changes), LARGE_THRESHOLD))
print("To change: %d | Applied: %d | Skipped: %d" % (len(changes), applied, len(skipped)))
for label, old, new, _ in changes[:200]:
    print("%s: %s -> %s" % (label, old, new))
for s in skipped[:50]:
    print("SKIPPED %s" % (s,))
