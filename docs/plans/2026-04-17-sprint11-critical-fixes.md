# Sprint 11 Critical Fixes Plan

## Scope

- Mobile local data lifecycle and onboarding/settings flows
- Mobile database encryption and recovery UX
- Mobile vector DB integrity and import deduplication
- Mobile API client hardening and runtime-path UI
- Backend seed parity update
- CI branch filter correction

## Constraints

- Preserve FastAPI API contract compatibility.
- Keep demo data opt-in only.
- Do not derive encryption keys from device metadata.
- Keep existing local data model compatible unless a migration is strictly required.

## Implementation Order

1. Fix `LifeRecordStore` seeding lifecycle so initialization only creates tables, demo data loads explicitly, and delete-all clears demo state.
2. Redesign database key management around secure-storage-only master keys, then add missing-key recovery and tests.
3. Enable SQLite foreign keys, delete stale embeddings before replace/upsert, add orphan cleanup, and cover with tests.
4. Switch file import dedupe and history tracking to SHA-256 content hashes.
5. Harden remote API handling with timeout, safe JSON parsing, retry behavior, and tests.
6. Surface runtime path on the home response card.
7. Align backend seed records with the 14-record mobile seed corpus.
8. Fix GitHub Actions branch filters for `master`.

## Risks

- Existing encrypted local rows may fail to decrypt if a prior install used the old volatile key derivation. Recovery UX must be explicit and non-silent.
- SQLite integrity changes can affect import/update paths and require careful regression coverage.
- Seed parity must preserve current backend response schema while updating content only.

## Validation

- `cd mobile && flutter pub get`
- `cd mobile && flutter analyze`
- `cd mobile && flutter test`
- `python3 -m pytest backend/tests -q`
- `python3 -m ruff check backend/app backend/tests`
- `python3 -m mypy backend/app`
- `./scripts/export-openapi.sh`
- `./scripts/validate-docs.sh`
- `python3 scripts/check_seed_source_consistency.py`
