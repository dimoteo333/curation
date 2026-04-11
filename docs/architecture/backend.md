# Backend architecture

- routers -> services -> repositories -> db/models
- routers must not contain business rules
- services must be pure domain/application logic when possible
- repositories isolate SQLAlchemy access
- pydantic schemas are the API boundary
