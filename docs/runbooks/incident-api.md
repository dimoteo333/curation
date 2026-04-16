# API incident runbook

## Immediate checks

1. Start the API locally with `bash scripts/run-api.sh`.
2. Verify health with `curl http://127.0.0.1:8000/health`.
3. Verify the curation endpoint with:

```bash
curl \
  -X POST http://127.0.0.1:8000/api/v1/curation/query \
  -H 'Content-Type: application/json' \
  -d '{"question":"나 요즘 왜 이렇게 무기력하지?","top_k":3}'
```

## What to inspect

- Router wiring in `backend/app/main.py`
- Seeded records in `backend/app/db/seed_records.py`
- Query matching rules in `backend/app/services/curation_service.py`
- OpenAPI drift in `backend/openapi.json`

## Recovery steps

- If `/health` fails, inspect dependency installation and startup logs first.
- If `/health` works but the curation payload is wrong, reproduce with `python3 -m pytest backend/tests -q`.
- If contract drift is suspected, re-run `bash scripts/export-openapi.sh` and compare changes before committing.
