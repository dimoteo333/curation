# 2026-04-16 Initial Implementation Plan

## Service goal summary

Build the first validated implementation of Curator as a Flutter mobile client plus FastAPI backend that demonstrates a Korean-first personal-curation vertical slice while preserving additive API compatibility and keeping repository docs, contracts, and harness commands as the source of truth.

## Assumptions

- The current repository is a scaffold: docs, workflows, and shell entrypoints exist, but `mobile/` and `backend/` product code does not exist yet.
- The initial implementation should favor a narrow, testable vertical slice over broad feature coverage.
- Because the README describes an eventual on-device RAG product while this repository explicitly contains a FastAPI backend, the first implementation may use the backend as a development/demo slice without claiming that private data leaves the device in the final architecture.
- All user-facing text in the initial slice should be Korean unless a document or developer-only artifact is explicitly English.
- API changes must remain additive within this initial implementation and be reflected in `backend/openapi.json` and `docs/architecture/contracts.md`.

## Milestone list

### Phase 1. Repository understanding and harness alignment

1. Confirm repository intent from `README.md`, `AGENTS.md`, architecture docs, scripts, and CI workflow files.
2. Record the gap between the expected harness and the actual scaffolded repository state.
3. Define the initial vertical slice and validation strategy inside this plan before broad product code is added.

### Phase 2. Development harness

1. Scaffold the FastAPI backend with architecture-aligned modules, dependency manifest, and baseline tests.
2. Scaffold the Flutter mobile client with architecture-aligned folders, dependency manifest, and baseline tests.
3. Implement or repair repository scripts so the documented validation commands work from a clean checkout.

### Phase 3. Vertical slice implementation

1. Implement an additive backend API for a Korean curation query over seeded personal records.
2. Implement a mobile screen and state flow that calls the backend and renders the curated result in Korean.
3. Add unit or integration coverage for the backend service, API contract, and mobile presentation path.

### Phase 4. Quality and legibility

1. Export and commit the generated OpenAPI contract.
2. Update repository docs so architecture, contracts, and runbooks describe the implemented slice and harness behavior.
3. Tighten tests, linting, and sample data so future agent runs can extend the codebase without rediscovery work.

### Phase 5. Optional long-run orchestration readiness

1. Add a minimal, explicit readiness artifact only if it materially improves future incremental work without inventing infrastructure.
2. Keep this phase bounded to repo legibility and local orchestration, not speculative platform expansion.

## Acceptance criteria

- `docs/plans/2026-04-16-initial-implementation-plan.md` exists and is kept current during implementation.
- The repository contains working `backend/` and `mobile/` projects that follow the documented architecture boundaries.
- The initial vertical slice supports a Korean user question and returns a structured curated response over seeded personal records.
- Mobile and backend tests cover the implemented behavior at an appropriate slice depth.
- `backend/openapi.json` matches the implemented FastAPI app.
- Documentation and runbooks reflect the current implementation and harness behavior.
- Required validation commands pass, or any environment-specific blocker is documented precisely in the progress log.

## Validation commands

- `cd mobile && flutter pub get`
- `cd mobile && flutter analyze`
- `cd mobile && flutter test`
- `python -m pytest backend/tests`
- `python -m ruff check backend/app backend/tests`
- `python -m mypy backend/app`
- `./scripts/export-openapi.sh`
- `./scripts/validate-docs.sh`

## Risks and open questions

- The README targets an eventual on-device architecture, but the repository also requires a FastAPI backend. The initial slice must stay explicit that it is a repository implementation harness, not a final privacy architecture claim.
- Flutter and Python toolchains may not both be installed in the execution environment; if a required command fails for environment reasons, capture the exact blocker and keep the repository state otherwise valid.
- iOS simulator validation is required by policy for PRs, but local execution depends on the available Flutter/iOS environment.
- The exact first API surface is not specified in docs, so the initial slice must remain narrow and additive.

## Progress log

- 2026-04-16: Read `README.md`, `AGENTS.md`, architecture docs, scripts, and GitHub workflows.
- 2026-04-16: Confirmed the repository currently contains documentation and harness stubs only; `backend/` and `mobile/` implementation directories are not present yet.
- 2026-04-16: Chosen initial implementation strategy: scaffold the harness first, then add a single Korean curation query vertical slice over seeded records.
- 2026-04-16: Scaffolded `mobile/` with Flutter and implemented the first presentation/state/domain/data slice for a Korean curation query.
- 2026-04-16: Implemented `backend/` with FastAPI routers, services, repositories, seeded records, tests, and exported OpenAPI.
- 2026-04-16: Added local harness resilience by allowing scripts and `Makefile` to use `python3` when `python` is unavailable.
- 2026-04-16: Validation pass succeeded for backend tests, Ruff, mypy, Flutter analyze, Flutter test, OpenAPI export, and docs validation.
- 2026-04-16: iOS integration validation is currently blocked locally because no available iOS simulator runtime is installed on this machine.

## Decision log

- 2026-04-16: Treat repository documents and workflows as the implementation contract; do not infer undocumented product scope.
- 2026-04-16: Use a narrow seeded-data curation flow as the first vertical slice because it exercises backend, mobile, tests, and OpenAPI without forcing speculative ingestion or on-device model integration.
- 2026-04-16: Keep all behavior additive and document any divergence between the long-term README vision and the initial repository-backed implementation.
- 2026-04-16: Keep Phase 5 intentionally light; documentation and harness readiness were more valuable than speculative orchestration code for this repository state.
