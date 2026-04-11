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
