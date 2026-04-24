# Sprint 12 Quality Improvements Plan

## Scope

- iOS simulator CI lane remote-harness verification
- Backend curation ranking and explanation quality improvements
- Mobile dead code cleanup and settings developer-section separation
- Test refactoring away from brittle copy snapshots

## Goals

1. Make the iOS simulator lane prove that the booted FastAPI harness is actually used.
2. Improve backend ranking quality without changing request/response schema.
3. Remove stale mobile code paths and keep `flutter analyze` clean.
4. Shift tests toward behavioral assertions so wording can evolve safely.
5. Keep developer-only runtime configuration visibly separate in settings.

## Planned Changes

1. Update `.github/workflows/ios-simulator.yml`, `scripts/run-ios-sim-tests.sh`, and remote integration coverage so CI-only runs compare rendered UI against a live backend response.
2. Rework `backend/app/services/curation_service.py` scoring to combine semantic expansion, phrase/context weighting, theme alignment, and grounded explanation selection.
3. Update backend tests to check ranking behavior and grounded response properties rather than exact prose.
4. Remove or confirm absence of stale mobile dead code targets, then clean nearby compatibility leftovers if any remain.
5. Refactor settings developer controls into a more explicit isolated section and adjust tests accordingly.
6. Update review/documentation text where Sprint 12 claims depend on these fixes.

## Constraints

- Preserve FastAPI HTTP contract compatibility.
- Keep remote-harness verification gated to CI-only behavior.
- Do not weaken required validation or guardrail scripts.

## Validation

- `cd mobile && flutter pub get`
- `cd mobile && flutter analyze`
- `cd mobile && flutter test`
- `python3 -m pytest backend/tests -q`
- `python3 -m ruff check backend/app backend/tests`
- `python3 -m mypy backend/app`
- `bash scripts/export-openapi.sh`
- `bash scripts/validate-docs.sh`
