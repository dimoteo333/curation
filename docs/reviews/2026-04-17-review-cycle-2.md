# Review Cycle 2 — Sprint 12

## Score

- Previous score: `4/10`
- New score: `8.5/10`

## Sprint 11 Fix Verification

| Sprint 11 fix | Status | Notes |
| --- | --- | --- |
| Demo data no longer auto-reseeds after delete/reset | Properly fixed | `LifeRecordStore.initialize()` now only opens the local DB, while demo data is loaded only from onboarding/settings via `loadDemoData()`. Sprint 12 also removed the unused `demo_data_loaded` preference flag. |
| Encryption uses stable keys only | Properly fixed | `DatabaseEncryption` now uses a per-install secure-storage master key without device-fingerprint/system-version derivation, and explicitly throws recovery exceptions when the key is missing or invalid. |
| SQLite foreign keys are enabled | Properly fixed | `VectorDb._open()` enables `PRAGMA foreign_keys = ON`, cleans orphan embeddings on startup, and deletes stale embedding rows before deduplicated upserts. |
| File dedupe uses content-based SHA-256 | Properly fixed | `FileRecordImportService` hashes raw file bytes with SHA-256, uses that digest as `contentHash`, and derives stable `sourceId` values from the hash. |
| `ApiClient` is hardened | Properly fixed | Remote requests now use explicit timeout handling, bounded retry on timeout/5xx, safe error-message extraction, and controlled JSON decode failures. |
| Home screen shows runtime path | Properly fixed | The response card now renders a runtime badge for on-device native, on-device fallback, and remote harness responses. |

## What Changed In Sprint 12

- The iOS simulator lane now runs a real remote-harness UI test with `flutter drive`, explicit `CURATION_MODE=remote`, and `API_BASE_URL` dart defines instead of booting FastAPI and never consuming it.
- The backend curation harness was upgraded from a generic keyword response to a more grounded evidence summary with better ranking signals, theme-aware insight titles, and record-backed explanations while preserving the HTTP contract.
- Mobile dead code was cleaned up by removing the stale `KeywordHashEmbeddingService`, the one-line `file_import_service.dart` re-export, and the unused demo-data-loaded preference bookkeeping.
- Copy-heavy fallback tests were relaxed toward behavioral assertions so text polish can evolve without hiding real regressions.
- The settings screen now separates developer runtime/model-path controls from ordinary user settings with an explicit developer section.

## Remaining Issues

### Critical

- None identified in this cycle after Sprint 12 remediation.

### Significant

- None identified in this cycle after Sprint 12 remediation.

### Minor

- None identified as blocking quality issues after Sprint 12 remediation.

## Recommended Fixes For Next Cycle

1. Add a real-device lane for native LLM/model loading so simulator coverage and host-side integration coverage are complemented by hardware validation.
2. Broaden calendar regression coverage around recurring-event semantics, since plugin `eventId` behavior can still differ by platform/account type.
3. Expand the backend harness corpus or scenario tests if the remote mode is expected to remain a meaningful comparison target for demos and manual QA.
