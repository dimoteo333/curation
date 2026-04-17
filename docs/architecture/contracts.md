# API contract rules

- backend/openapi.json is the machine-readable source of truth
- Every endpoint change must update OpenAPI export
- Mobile DTOs must be generated or manually synced from OpenAPI
- If response shape changes, update integration tests first

## Current endpoints

### `GET /health`

- Purpose: confirm API liveness and seeded record availability
- Response shape:
  - `status`: string
  - `record_count`: integer

### `POST /api/v1/curation/query`

- Purpose: return a Korean curation response for a user question
- Request shape:
  - `question`: string, required, 2..280 chars
  - `top_k`: integer, optional, 1..5
- Response shape:
  - `insight_title`: string
  - `summary`: string
  - `answer`: string
  - `supporting_records`: array
  - `suggested_follow_up`: string

### `supporting_records[]`

- `id`: string
- `source`: string
- `title`: string
- `created_at`: ISO-8601 datetime string
- `excerpt`: string
- `relevance_reason`: string

## Sync expectations

- Mobile DTOs in `mobile/lib/src/data/dto/curated_response_dto.dart` remain manually synced to the current OpenAPI contract for remote harness mode.
- The default mobile runtime now maps local on-device retrieval and generation results into the same domain response shape used by the UI.
- Sprint 3 does not change backend HTTP request/response shapes. `backend/openapi.json` therefore remains unchanged.
- The mobile-local `LifeRecord` persistence model is internal to the on-device store and now includes `sourceId`, `importSource`, and `metadata` for deduplication and source-specific ingest details; these fields do not alter the FastAPI contract.
- Any additive response change must update `backend/openapi.json`, mobile DTOs, and backend/mobile tests in the same change.
