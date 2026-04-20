# Mobile architecture

- Presentation: widgets/screens
- State: Riverpod or Bloc providers/controllers
- Domain: use-cases and entities
- Data: repositories, dto, remote/local sources

Rules

- UI must not call Dio/HTTP directly.
- State layer can depend on domain, not on concrete API clients.
- Repository implementations stay in data layer.
- Feature flags must be centralized.

## Current implementation slice

- App root: `mobile/lib/main.dart` -> `ProviderScope` -> `CuratorApp`
- Presentation:
  - `mobile/lib/src/presentation/screens/onboarding_screen.dart`
  - `mobile/lib/src/presentation/screens/home_screen.dart`
  - `mobile/lib/src/presentation/screens/settings_screen.dart`
- State:
  - `mobile/lib/src/state/app_settings_controller.dart`
  - `mobile/lib/src/state/curation_controller.dart`
- Domain: `mobile/lib/src/domain/**`
- Data: `mobile/lib/src/data/**`
- Provider wiring: `mobile/lib/src/providers.dart`
- On-device bridge details: `docs/architecture/mobile-ondevice-llm.md`

## API usage rules

- The mobile app now defaults to an on-device curation path.
- The FastAPI development harness remains available through `CURATION_MODE=remote`.
- Base URL configuration comes from `API_BASE_URL` via `--dart-define`.
- The remote data source still owns JSON and HTTP concerns when remote mode is selected.
- The on-device path owns local vector search, Korean prompt construction, and native runtime bridging.
- UI and controller layers operate only on domain entities and use cases.

## On-device flow

- On first launch, a minimal onboarding screen explains the service, file import entry point, privacy posture, and optional demo-data loading. Completion is persisted with SharedPreferences.
- The app records `app.first_run_version` on the first successful launch so later launches can skip onboarding and future "what's new" flows have stable version metadata.
- Startup never hard-blocks on stale encrypted local data: if SQLite files remain but the secure-stored master key is missing, or if the local DB is corrupted, the app shows a Korean recovery screen with a destructive reset path back to onboarding.
- Runtime mode and developer model paths are stored as local settings and can override compile-time defaults without changing the API contract.
- Imported records and explicitly loaded demo records are indexed into a local encrypted SQLite vector store.
- `.txt` and `.md` files can be imported through the settings screen, parsed into local `LifeRecord` records, and embedded into the local vector DB.
- Device calendar events from the last 30 days can be imported on demand after a settings-screen permission grant and are stored as local `calendar` records for curation context.
- Apple Notes is not read directly; iOS users are guided to export note text to `.txt` and then reuse the file import path.
- Personal text fields in the local store are encrypted at the application layer with a per-install master key stored in secure storage, while embedding vectors remain plaintext for retrieval.
- Settings now expose a privacy policy reference, an explicit demo-data load action when the local DB is empty, and a destructive delete-all flow that removes the SQLite files, clears the secure-stored master key, and clears local app preferences.
- Settings also expose calendar sync status, last sync time, import history, and a data-source summary so local ingest state is visible to the user.
- If onboarding finishes without demo data, the home screen remains usable and shows an empty-state prompt to import records or load demo data later.
- Developer-only model path controls are grouped behind an explicit runtime section so ordinary user settings stay separate from local debug/runtime configuration.
- Query embeddings currently use the pure Dart `SemanticEmbeddingService` fallback on both iOS and Android.
- Local retrieval now keeps a tag-cluster ANN-style prefilter, persisted normalized embedding state, and an LRU repeated-question cache so searches do not rescore the full local corpus on every query.
- Native `embed` bridge calls are intentionally unavailable on both platforms
  until a stable public on-device text embedding path is available.
- The local vector store keeps normalized embedding and repeated-query caches so small datasets stay responsive without changing the retrieval contract.
- `LifeRecord` now carries `sourceId` for stable local deduplication, `source` for Korean UI display, `importSource` for extensible source typing, and `metadata` for source-specific details.
- iOS keeps the legacy MediaPipe bridge for non-`.litertlm` experiments, but
  public Gemma 4 LiteRT-LM `.litertlm` loading is not currently exposed through
  a documented Swift SDK path, so that configuration remains fallback-only.
- Python is not a documented LiteRT-LM iOS app path, and the plausible future
  Gemma 4 route on iOS is a source-built C++ bridge that this repository does
  not yet bundle or validate.
- Android can compile and run the native LiteRT-LM bridge with `minSdk >= 24`,
  pinned `litertlm-android` dependencies, optional OpenCL native-library
  manifest declarations, and release ProGuard rules that keep LiteRT-LM/TFLite
  classes.
- Both platforms return the same native runtime status shape and fall back to the same Dart semantic embedding path when models are missing or initialization fails.
- The curation answer is generated from Korean prompt templates and retrieved local context, with native generation used only when the LLM bridge reports partial native readiness.
- Large model artifacts are staged outside the repository and passed by `LLM_MODEL_PATH` and `EMBEDDER_MODEL_PATH`.

## Tests

- Widget test uses a fake repository override to validate presentation without network access.
- Mobile unit tests cover:
  - local vector store search and v1 -> v2 schema migration
  - file import parsing and local persistence
  - calendar event conversion and import history tracking
  - local deduplication on `(import_source, source_id)` upsert
  - on-device repository path without network access
  - onboarding and settings widgets
- Integration test now validates the default on-device rendering path on a supported simulator/device.
- A dedicated remote-harness integration test now drives the app against the FastAPI backend on iOS simulator with explicit `CURATION_MODE=remote` and `API_BASE_URL` dart defines.
- Android debug build verification should include at least one `flutter build apk --debug` smoke test in addition to `flutter analyze` and `flutter test`.
