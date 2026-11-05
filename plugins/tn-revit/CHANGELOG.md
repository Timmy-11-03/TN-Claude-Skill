# Changelog

## 0.2.0
- Add `revit-change-case` (migrated from standalone skill). Script moved to `_shared/scripts/change_case.py`.
- Script now uses a named transaction `TN: revit-change-case`, rollback on error, and a 200-change confirmation guard.

## 0.1.0
- Initial plugin scaffold: manifest, shared safety rules, naming conventions, audit skill template.
