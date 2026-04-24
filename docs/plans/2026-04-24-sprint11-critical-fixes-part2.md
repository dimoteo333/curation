# Sprint 11 Critical Fixes Part 2 Plan

## Scope

- Mobile API client hardening for remote harness mode
- Mobile recent-conversation runtime path persistence and home-screen badge UI
- Backend seed parity with the 14-record mobile demo corpus
- CI branch filter fixes for `master`

## Constraints

- Preserve the FastAPI request/response contract shape.
- Keep runtime-path UI additive and backward-compatible with stored recent-conversation data.
- Keep mobile/backend seed IDs aligned and source vocabulary consistent.

## Implementation

1. Reduce the default remote API timeout, guard JSON parsing with explicit `FormatException` handling, and improve HTTP/network error messages without changing response DTO shapes.
2. Extend `RecentConversation` to persist runtime path metadata, derive a compact badge label from `CurationRuntimeInfo`, and render the badge on the home recent-conversation cards.
3. Replace backend seed records with the same 14 records shipped on mobile, matching ID/title/content/source semantics closely enough for parity checks and remote-harness behavior.
4. Add `master` to the `docs-guard` and `ios-simulator` pull-request branch filters.

## Risks

- Old recent-conversation payloads in `SharedPreferences` may be missing runtime metadata or contain malformed JSON; the controller should degrade to an empty list instead of crashing.
- Changing backend seed `source` values affects ranking heuristics and remote-harness UI wording, so source-dependent logic must be updated together.

## Validation

- `cd mobile && flutter analyze`
- `cd mobile && flutter test`
- `python3 -m pytest backend/tests -q`
- `python3 -m ruff check backend/app backend/tests`
- `python3 -m mypy backend/app`
- `python3 scripts/check_seed_source_consistency.py`
