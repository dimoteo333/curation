# Comprehensive Code Review — 큐레이터 (Curator)

## Executive Summary
- Overall assessment: `4/10`
- Validation snapshot:
  - Passed: `flutter pub get`, `flutter analyze`, `flutter test`, `python3 -m pytest backend/tests`, `python3 -m ruff check backend/app backend/tests`, `python3 -m mypy backend/app`, `./scripts/export-openapi.sh`, `./scripts/validate-docs.sh`, `./scripts/check-openapi-drift.sh`
  - Failed: `python3 scripts/check_seed_source_consistency.py`
- Top 3 critical issues
  - Demo seed data is silently reintroduced after "모든 데이터 삭제", so user data can never stay cleanly deleted and personal curation remains polluted by sample records.
  - Local encryption keys are derived from volatile device metadata like OS version and Android fingerprint, so a device/OS change can make existing data undecryptable.
  - Deduplicated upserts in the local vector DB can leak orphan embedding rows because `REPLACE` is used without enabling SQLite foreign keys.
- Top 5 recommended improvements
  - Make sample data opt-in only; stop reseeding on normal initialization and after delete-all.
  - Redesign key derivation to use a stable per-install secret, then add migration and recovery coverage.
  - Fix vector upsert semantics so stale embeddings are deleted deterministically.
  - Replace file dedupe with a stable content/source hash instead of filename/path/mtime heuristics.
  - Align CI workflows and guardrails with the real default branch and actual runtime paths.

## Detailed Findings

### 🔴 Critical Issues (Must Fix)
- Demo records are treated as permanent app state, not optional sample data. `LifeRecordStore.initialize()` seeds records whenever `_bootstrapKey` is false and the DB is empty, while `deleteAllData()` clears the same preferences key. That means opening the app, asking a question, or loading stats after "모든 데이터 삭제" will repopulate the sample corpus. This is a trust-breaking behavior for a personal curation app and makes the delete-all flow materially misleading. Refs: `mobile/lib/src/data/local/life_record_store.dart:34-47`, `mobile/lib/src/data/local/life_record_store.dart:64-76`.
- Database encryption is bound to unstable device context. The key derivation mixes the stored master key with Android fingerprint / SDK version or iOS system version and hardware identifiers. OS updates, some device migrations, and certain restore/reinstall scenarios can therefore make previously encrypted rows impossible to decrypt even though the secure-stored master key still exists. This is a data-loss design flaw, not just a hardening gap. Refs: `mobile/lib/src/providers.dart:48-79`, `mobile/lib/src/core/security/database_encryption.dart:110-115`.
- `VectorDb` relies on `ConflictAlgorithm.replace` against `(import_source, source_id)` while defining `embeddings.doc_id` as `FOREIGN KEY ... ON DELETE CASCADE`, but the database is opened without enabling SQLite foreign keys. When a duplicate import arrives with a new `id`, SQLite replaces the document row and leaves the old embedding row behind. Search joins currently hide the orphan rows, but DB size, migrations, and future maintenance drift. Refs: `mobile/lib/src/data/local/vector_db.dart:250-313`, `mobile/lib/src/data/local/vector_db.dart:542-613`.

### 🟡 Significant Issues (Should Fix)
- File import dedupe is not stable. Imported-file history is keyed by `path + modifiedAt`, and the stored `sourceId` is derived from `file name fingerprint + modifiedAt`. Rename the same file, re-export identical content, or import the same note from a different folder and it becomes a brand-new record. The docs claim stable local deduplication, but the implementation is still filename/mtime-based. Refs: `mobile/lib/src/data/import/file_record_import_service.dart:60-66`, `mobile/lib/src/data/import/file_record_import_service.dart:127-166`.
- The custom seed-consistency guard already fails in the current repository. Backend still ships 5 seeded records while mobile ships 14, so remote harness behavior and on-device behavior are now based on different corpora. This breaks the stated "same seed/source vocabulary" discipline and weakens any cross-layer validation. Refs: `backend/app/db/seed_records.py:8-64`, `mobile/lib/src/data/local/seed_records.dart:26-251`. Confirmed by `python3 scripts/check_seed_source_consistency.py` on `2026-04-17`.
- CI branch coverage is inconsistent with the repository’s actual workflow. `pr-gate.yml` watches `master` and `main`, but `docs-guard.yml` and `ios-simulator.yml` only watch `main` and `develop`. On a `master`-based PR flow, docs/native guardrails and simulator coverage simply do not run. Refs: `.github/workflows/docs-guard.yml:3-6`, `.github/workflows/ios-simulator.yml:3-6`, `.github/workflows/pr-gate.yml`.
- The iOS "integration" lane is not validating what it claims. The workflow boots FastAPI, but `scripts/run-ios-sim-tests.sh` only runs `flutter test integration_test`. The existing integration tests stay on the on-device/fake paths and do not assert backend connectivity or native bridge readiness on simulator hardware. The job looks expensive and reassuring, but it is not exercising the critical path it advertises. Refs: `.github/workflows/ios-simulator.yml:38-47`, `scripts/run-ios-sim-tests.sh:4-7`, `mobile/integration_test/app_test.dart:12-31`, `mobile/integration_test/full_pipeline_test.dart:42-101`.
- Remote-mode error handling is fragile. `ApiClient.postJson()` has no timeout and unconditionally `jsonDecode`s the body before checking status codes. A reverse proxy HTML error page, empty `502`, or plain-text failure turns into a raw `FormatException`, and a slow or dead connection can hang indefinitely. Refs: `mobile/lib/src/core/network/api_client.dart:21-41`.
- The main UX hides the runtime path even though the code has `runtimeInfo` and the docs explicitly say fallback status should not be hidden. Home response cards never render whether the answer came from native generation, template fallback, or remote harness, so the product’s trust model is opaque at the most important point in the flow. Refs: `mobile/lib/src/domain/entities/curated_response.dart:28-50`, `mobile/lib/src/presentation/screens/home_screen.dart:334-390`.
- The backend harness is too toy-like to be a reliable proxy for the mobile product. It ranks a 5-record static corpus by token overlap and synonym expansion, which is fine for a smoke harness, but it is not a meaningful validation target for the on-device RAG behavior the app actually ships. Refs: `backend/app/services/curation_service.py:27-94`, `backend/app/db/seed_records.py:8-64`.

### 🟢 Minor Issues (Nice to Fix)
- Settings shows `수동 0건` even though no `manual` import source exists anywhere in the mobile data model. This is dead UI vocabulary and makes the data-source summary look more complete than it is. Refs: `mobile/lib/src/presentation/screens/settings_screen.dart:677-681`.
- `KeywordHashEmbeddingService` is still in the repo but appears unused, and `file_import_service.dart` is only a one-line re-export. These are small dead-weight indicators that cleanup is lagging behind architecture changes. Refs: `mobile/lib/src/data/ondevice/keyword_hash_embedding_service.dart`, `mobile/lib/src/data/import/file_import_service.dart`.
- Several tests are copy-heavy snapshot assertions on curated strings rather than invariant-driven assertions. They are good at catching text churn, not at catching behavioral regressions. Refs: `mobile/test/llm_engine_test.dart`, `mobile/test/template_response_quality_test.dart`.
- The root `README.md` still describes connectors and capabilities such as OCR, voice memo ingestion, and multimodal flows that do not exist in this codebase. That is a completeness/documentation accuracy problem, not just aspirational marketing.

## 📊 Per-Module Analysis

### Data Layer

#### VectorDb
- This is the most substantial implementation in the app. It has migrations, encryption, normalization, tag-cluster prefiltering, caching, and direct tests.
- The quality is uneven because lifecycle guarantees are weak. The orphan-embedding issue is serious, and there is no explicit foreign-key enablement despite relying on cascading semantics.
- Search is still fundamentally an in-memory snapshot over all indexed documents after a lightweight prefilter. That is acceptable for demo scale, but the architecture docs talk more confidently about ANN-like behavior than the implementation deserves.
- Cache invalidation is tied to data mutation, not to embedding-runtime changes, so retrieval behavior can become stale if the embedding path changes during a session.

#### File Import
- Parsing and sanitization are decent. The service correctly rejects invalid names, invalid UTF-8, unsupported extensions, and oversized files.
- The dedupe strategy is not robust enough for a personal archive product. It is easy to duplicate the same note across paths, exports, and renames.
- Failures are collapsed into `skippedFiles` without detailed reason tracking, which makes debugging user import failures harder than it should be.

#### Calendar Import
- Permission states are modeled explicitly and surfaced into settings, which is a good baseline.
- The implementation dedupes by `eventId` only and keeps the latest occurrence. If the plugin reuses IDs for recurring events, the service will collapse multiple real calendar occurrences into one record and lose chronology. Refs: `mobile/lib/src/data/import/calendar_import_service.dart:271-279`. This is a likely bug, though it depends on plugin semantics.
- The service also records history even when `records` is empty, which is good for auditability.

#### Encryption
- Encrypting `title`, `content`, `tags_json`, and `metadata_json` at the application layer is materially better than leaving personal text in plaintext SQLite.
- Leaving vectors unencrypted is a pragmatic retrieval tradeoff, but it should be documented more bluntly because embeddings can still leak sensitive similarity structure.
- The key-derivation design is currently the main security/correctness liability in the whole mobile stack.

### Domain Layer

#### LLM Engine
- The fallback templates are better than expected for a non-LLM path. They at least preserve Korean tone and some temporal context.
- Native generation still depends on prompt discipline alone. There is no structured output contract, no validation that the quote is actually grounded, and no guard against the native model drifting away from the expected answer format.
- `LlmEngine` is doing prompt engineering, temporal reasoning, theme extraction, and fallback answer assembly all in one class. It is coherent today, but it is already large enough to become a maintenance hotspot.

#### Embedding Services
- `SemanticEmbeddingService` is elaborate, heuristic, and very hand-tuned. That is fine for an offline prototype, but there is no benchmark corpus or regression dataset proving retrieval quality.
- The repo has moved away from the older keyword-hash fallback, but the dead class is still present.
- The native embedder path is intentionally unavailable, which is honest in code, but a lot of product language still reads as if semantic retrieval is already backed by a production-grade model.

#### Use Cases
- `RequestCurationUseCase` is effectively a pass-through. That is not wrong, but it means real business invariants are concentrated in repositories and services instead of a stable domain boundary.
- The domain layer is thin enough that the architecture is still "layered" mostly by folder structure, not by strong abstraction pressure.

### Presentation Layer

#### Home Screen
- The visual design is intentional and differentiated. It does not look like boilerplate Flutter.
- The core trust signal is missing. Users do not see whether the answer came from native generation, a fallback template, or the remote harness.
- The response card only surfaces the first supporting record even though the domain response can carry multiple. That leaves retrieval transparency weaker than the data model suggests.

#### Onboarding
- The onboarding flow is polished and reasonably well tested.
- Its privacy message over-promises in the current product state because sample data is automatically reseeded and remote mode still exists in settings.

#### Settings
- Settings is feature-rich and exposes useful operational state.
- It is also where some of the product’s most misleading behavior lives: "모든 데이터 삭제" is not durable because initialization will reseed sample records.
- The screen has become the operational dumping ground for runtime, imports, privacy copy, model paths, and app metadata. It still works, but the cohesion is weakening.

#### Theme
- The theming is distinct, consistent, and one of the stronger parts of the repository.
- The downside is concentration: almost all visual tokens and motion decisions live in one large file, so later changes will become brittle unless the design system is split into smaller units.

### Backend

#### API
- The FastAPI surface is tiny and contract-stable.
- As a development harness it works, but it should not be confused with a meaningful backend for the actual product. There is no persistence, auth, telemetry, or realistic retrieval.
- The response schema is also blind to runtime-path metadata, which makes remote vs local behavior harder to compare in the client.

#### Service
- `CurationService` is readable and deterministic.
- It is also basically a seeded keyword matcher with handcrafted synonyms and a diary bonus. That is acceptable for smoke testing but weak as a parity target for the mobile experience.
- The quality of returned explanations is driven more by canned phrasing than by evidence composition.

#### Schemas
- Pydantic request validation is straightforward and correct for the current scope.
- The schema surface is so small that it is hard to get wrong, but it also means a lot of product state is not represented in the contract at all.

### Infrastructure

#### CI/CD
- The repository has more guardrail intent than many prototypes: backend linting, mypy, Flutter analysis/tests, OpenAPI export, docs validation, native dependency guards, release signing checks.
- The enforcement is inconsistent. Critical jobs do not all run on the actual default branch flow, and one important custom guard already fails locally.
- The simulator lane is the biggest example of "looks stronger than it is."

#### Scripts
- The scripts are short and readable.
- `check_seed_source_consistency.py` is useful and currently proving its value by failing.
- The script set is still mostly a collection of one-purpose guards, not an integrated release discipline.

#### Guardrails
- The docs in `docs/contributing.md` and `docs/runbooks/guardrails.md` are stronger than the codebase discipline.
- The biggest pattern in this repo is not lack of awareness. It is that the docs often know the correct rule before the implementation actually meets it.

### Test Coverage Assessment
- What IS tested
  - Mobile vector-store search, schema migration, encryption-at-rest happy paths, file import parsing, calendar import happy path, widget rendering, and a few fallback-response behaviors.
  - Backend health and curation smoke responses.
- What is NOT tested but should be
  - Delete-all followed by app restart / stats reload.
  - Device-context changes breaking decryption.
  - Orphan embedding cleanup after deduplicated upserts.
  - Remote-mode timeout, invalid JSON, and non-200 error handling.
  - Calendar denied/restricted flows end-to-end.
  - Native bridge behavior on real Android and iOS hardware with actual models.
  - Backend/mobile seed-parity enforcement in the always-on gate.
  - Recurring calendar event semantics.
- Test quality concerns
  - Too many tests assert exact Korean copy instead of stronger behavioral invariants.
  - The integration tests are mislabeled stronger than they are. They are mostly widget/repository tests running through `flutter test`, not end-to-end mobile platform verification.
  - Green test runs currently coexist with product-trust bugs that users would notice immediately.

### Security Assessment
- Data encryption status
  - Sensitive text fields are encrypted with AES-GCM at the application layer.
  - Embeddings remain plaintext, which is a pragmatic but non-trivial privacy tradeoff.
  - Key derivation is currently unsafe because it depends on unstable device metadata.
- Input validation status
  - Mobile input/file sanitization is present and better than average for a prototype.
  - Backend request validation is minimal but adequate for the current schema.
  - Remote error handling is weak and can surface raw exceptions instead of controlled failures.
- Permission handling status
  - Calendar permission states are modeled and surfaced.
  - Denied/restricted behavior is under-tested.
- Potential vulnerabilities
  - "Delete all" does not behave durably because data reseeds later.
  - A device/OS context change can effectively brick encrypted local content.
  - Remote-mode failures can leak implementation details through unhandled parse/network errors.

### Architecture Assessment
- Layer separation quality
  - Folder-level layering is mostly clean. UI is not reaching into HTTP, and router/service separation in backend is respected.
  - The deeper problem is invariant placement. Real product guarantees are still buried in data-layer side effects rather than formalized in the domain layer.
- Dependency direction correctness
  - Mostly correct on mobile and backend.
  - The weak point is that operational concerns like seeding, encryption, and import identity leak across multiple layers without a single authoritative policy.
- State management patterns
  - Riverpod usage is sane and readable.
  - Some provider-triggered behaviors are surprising, especially the fact that loading stats also initializes and seeds the local store.
- Scalability concerns
  - Retrieval quality is heuristic and demo-scale.
  - The backend harness is already diverging from the mobile corpus.
  - CI gives a stronger impression of platform validation than it currently provides.

## Recommended Action Items (Prioritized)
1. Remove implicit seed bootstrapping from normal initialization. Keep sample data behind an explicit "load demo data" action.
2. Redesign encryption to use a stable per-install secret only, then add migration and recovery tests for app updates and device changes.
3. Enable SQLite foreign keys on open and/or explicitly delete stale embeddings before replacing documents on `(import_source, source_id)` collisions.
4. Replace filename/path/mtime dedupe with a stable content-derived or source-system-derived identity model.
5. Decide whether the backend harness is meant to stay a smoke stub or become a parity target. If it stays a stub, stop presenting it as product-validation coverage.
6. Fix branch filters so `docs-guard` and `ios-simulator` run for the repo’s real PR path on `master`.
7. Replace the current iOS simulator lane with a test that actually exercises either remote mode or native-bridge behavior on simulator/hardware.
8. Harden `ApiClient` with timeouts, safe error decoding, and explicit tests for invalid/non-JSON responses.
9. Surface runtime path and fallback status in the main home experience using the existing `runtimeInfo` data.
10. Add regression tests for delete-all persistence, recurring calendar events, seed parity, and orphan embedding cleanup.
