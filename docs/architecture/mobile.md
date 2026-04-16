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

## API usage rules

- The current mobile slice talks only to the FastAPI development harness.
- Base URL configuration comes from `API_BASE_URL` via `--dart-define`.
- The remote data source owns JSON and HTTP concerns.
- UI and controller layers operate only on domain entities and use cases.

## Tests

- Widget test uses a fake repository override to validate presentation without network access.
- Integration test expects a running backend at `API_BASE_URL` and a supported simulator/device.
