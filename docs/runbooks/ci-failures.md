# CI failure runbook

## Backend failures

- Reinstall backend dependencies with `python3 -m pip install -r backend/requirements.txt pytest ruff mypy`.
- Re-run:
  - `python3 -m pytest backend/tests -q`
  - `python3 -m ruff check backend/app backend/tests`
  - `python3 -m mypy backend/app`

## Mobile failures

- Reinstall Flutter packages with `cd mobile && flutter pub get`.
- Re-run:
  - `cd mobile && flutter analyze`
  - `cd mobile && flutter test`

## Contract and docs failures

- Re-export OpenAPI with `bash scripts/export-openapi.sh`.
- Re-run docs validation with `bash scripts/validate-docs.sh`.
- If CI reports uncommitted drift after export, commit the regenerated `backend/openapi.json` and any matching doc/DTO updates.

## Local environment notes

- CI uses `python` on GitHub Actions. This machine only exposed `python3`, so local recovery commands may need `python3 -m ...`.
- iOS integration validation requires an installed iOS simulator runtime; absence of that runtime is an environment blocker, not an application failure.
