# AGENTS.md

## Mission
- This repository contains a Flutter mobile client and a FastAPI backend.
- Always preserve API contract compatibility unless the task explicitly allows breaking changes.

## Start here
1. Read docs/architecture/mobile.md
2. Read docs/architecture/backend.md
3. Read docs/architecture/contracts.md
4. If the task spans more than one layer, create docs/plans/<date>-<task>.md first.

## Change boundaries
- Mobile UI/state changes: mobile/lib/**
- Mobile tests: mobile/test/**, mobile/integration_test/**
- Backend API/domain changes: backend/app/**, backend/tests/**
- Contract updates: backend/openapi.json and docs/architecture/contracts.md
- Do not modify signing, certificates, or production secrets.

## Required checks
- flutter pub get
- flutter analyze
- flutter test
- python -m pytest backend/tests
- python -m ruff check backend/app backend/tests
- python -m mypy backend/app
- ./scripts/export-openapi.sh
- ./scripts/validate-docs.sh

## iOS-specific rules
- iOS simulator tests run only on macOS.
- Do not edit ios/Runner.xcodeproj settings unless task explicitly requires it.
- If simulator test fails, attach screenshot/log artifact summary in PR.

## PR format
- What changed
- Why
- Risk
- Validation
- Contract impact

## Escalate to human
- Schema migration with data rewrite
- Apple signing/certificate/profile change
- Breaking OpenAPI change
- Payment/auth/security-sensitive flows