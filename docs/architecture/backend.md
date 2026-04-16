# Backend architecture

- routers -> services -> repositories -> db/models
- routers must not contain business rules
- services must be pure domain/application logic when possible
- repositories isolate SQLAlchemy access
- pydantic schemas are the API boundary

## Current implementation slice

- App entrypoint: `backend/app/main.py`
- Routers: `backend/app/routers/health.py`, `backend/app/routers/curation.py`
- Services: `backend/app/services/curation_service.py`
- Repositories: `backend/app/repositories/seed_record_repository.py`
- DB/models: `backend/app/db/models.py`, `backend/app/db/seed_records.py`
- Schemas: `backend/app/schemas/curation.py`

## Current repository strategy

- The initial slice uses a seeded in-memory repository rather than persistent storage.
- Repository isolation is still preserved so seeded data can be replaced with real storage later.
- Curation behavior is deterministic and rule-based for the harness slice; no external model calls are made.

## Router boundary

- `GET /health` returns API liveness plus seeded record count.
- `POST /api/v1/curation/query` accepts a Korean question and returns a structured curated response.
