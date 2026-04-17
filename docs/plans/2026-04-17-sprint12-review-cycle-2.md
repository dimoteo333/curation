# Sprint 12 Review Cycle 2 Plan

## Scope

- Mobile review and remediation for remaining quality gaps after Sprint 11
- Backend harness quality improvements without breaking the existing API contract
- CI and simulator coverage fixes for the advertised test lanes
- Review and architecture documentation updates

## Findings To Address

1. The mandatory validation baseline passes, so Sprint 12 starts from a green repository state.
2. Sprint 11 direct fixes are largely effective:
   - Demo data is no longer auto-seeded.
   - Encryption now uses a stable per-install master key.
   - SQLite foreign keys are enabled and orphan embeddings are cleaned.
   - File dedupe now uses SHA-256 content hashes.
   - `ApiClient` has timeout and safe JSON/error handling.
   - Home screen surfaces the runtime path.
3. Remaining quality gaps still matter:
   - The iOS simulator lane still does not exercise the remote harness path it boots.
   - The backend harness is still too thin to be a useful comparison target.
   - Dead code remains in the mobile data layer.
   - Some tests still overfit exact Korean wording rather than behavioral invariants.
   - The settings screen is large and mixes user actions with developer-only model configuration.

## Planned Changes

1. Add a real remote-harness integration path for simulator runs and update the iOS script to execute it.
2. Strengthen backend ranking/explanation behavior while preserving the HTTP contract.
3. Remove unused mobile dead code and stale compatibility exports.
4. Rewrite fragile copy-heavy tests into behavior-driven assertions.
5. Improve settings-screen cohesion by isolating developer-only model configuration behind an explicit section gate.
6. Publish an updated review in `docs/reviews/2026-04-17-review-cycle-2.md`.

## Constraints

- Preserve FastAPI request and response compatibility.
- Keep default mobile behavior on-device-first.
- Do not weaken existing guardrail scripts or release checks.

## Validation

- `cd mobile && flutter analyze`
- `cd mobile && flutter test`
- `python3 -m pytest backend/tests -q`
- `python3 scripts/check_seed_source_consistency.py`
