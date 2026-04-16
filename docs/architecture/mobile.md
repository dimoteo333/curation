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
- Presentation: `mobile/lib/src/presentation/screens/home_screen.dart`
- State: `mobile/lib/src/state/curation_controller.dart`
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

- Seeded or imported records are indexed into a local SQLite vector store.
- Query embeddings run on device through a native bridge when available, or a deterministic local fallback in test environments.
- The curation answer is generated from Korean prompt templates and retrieved local context.
- Large model artifacts are staged outside the repository and passed by `LLM_MODEL_PATH` and `EMBEDDER_MODEL_PATH`.

## Tests

- Widget test uses a fake repository override to validate presentation without network access.
- Mobile unit tests cover the local vector store and the on-device repository path without network access.
- Integration test now validates the default on-device rendering path on a supported simulator/device.
