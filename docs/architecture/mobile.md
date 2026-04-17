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

- On first launch, a minimal onboarding screen explains the service, file import entry point, and privacy posture. Completion is persisted with SharedPreferences.
- Runtime mode and developer model paths are stored as local settings and can override compile-time defaults without changing the API contract.
- Seeded or imported records are indexed into a local encrypted SQLite vector store.
- `.txt` and `.md` files can be imported through the settings screen, parsed into `LifeRecord` v2 records, and embedded into the local vector DB.
- Personal text fields in the local store are encrypted at the application layer with a device-local key from secure storage, while embedding vectors remain plaintext for retrieval.
- Settings now expose a privacy policy reference and a destructive delete-all flow that removes the SQLite files and clears local app preferences.
- Query embeddings currently use the pure Dart `SemanticEmbeddingService` fallback on both iOS and Android.
- Local retrieval now keeps a tag-cluster ANN-style prefilter, persisted normalized embedding state, and an LRU repeated-question cache so searches do not rescore the full local corpus on every query.
- Native `embed` bridge calls are intentionally unavailable on both platforms until the MediaPipe text embedding path is stabilized.
- The local vector store keeps normalized embedding and repeated-query caches so small datasets stay responsive without changing the retrieval contract.
- `LifeRecord` now carries `source` for Korean UI display, `importSource` for extensible source typing, and `metadata` for source-specific details.
- iOS can use the native LiteRT LLM bridge when a model path is configured on a supported device, but text embedding still falls back to Dart because the current CocoaPods spec set does not resolve `MediaPipeTasksText`.
- Android can compile and run the native LiteRT LLM bridge with `minSdk >= 24`, pinned MediaPipe GenAI dependencies, and release ProGuard rules that keep MediaPipe/TFLite classes.
- Both platforms return the same native runtime status shape and fall back to the same Dart semantic embedding path when models are missing or initialization fails.
- The curation answer is generated from Korean prompt templates and retrieved local context, with native generation used only when the LLM bridge reports partial native readiness.
- Large model artifacts are staged outside the repository and passed by `LLM_MODEL_PATH` and `EMBEDDER_MODEL_PATH`.

## Tests

- Widget test uses a fake repository override to validate presentation without network access.
- Mobile unit tests cover:
  - local vector store search and v1 -> v2 schema migration
  - file import parsing and local persistence
  - on-device repository path without network access
  - onboarding and settings widgets
- Integration test now validates the default on-device rendering path on a supported simulator/device.
- Android debug build verification should include at least one `flutter build apk --debug` smoke test in addition to `flutter analyze` and `flutter test`.
