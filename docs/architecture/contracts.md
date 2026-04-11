# API contract rules

- backend/openapi.json is the machine-readable source of truth
- Every endpoint change must update OpenAPI export
- Mobile DTOs must be generated or manually synced from OpenAPI
- If response shape changes, update integration tests first
