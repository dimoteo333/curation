# Comprehensive Code Review Plan

Date: 2026-04-17
Scope: mobile, backend, tests, scripts, CI, and configuration

## Goals

- Review the implemented code, not just architecture docs, across Flutter mobile and FastAPI backend layers.
- Identify concrete correctness, security, performance, testing, and maintainability issues accumulated across sprints 1-10.
- Produce a prioritized review document with evidence tied to specific files and behaviors.

## Approach

1. Read required architecture, contracts, contributing, and guardrail documents.
2. Inspect mobile source by layer:
   - bootstrap and app wiring
   - providers and state
   - data and local persistence/import paths
   - domain services and use cases
   - presentation and theming
   - mobile unit and integration tests
3. Inspect backend source by layer:
   - app entrypoint and router setup
   - routers, services, repositories, schemas, db models
   - backend tests
4. Inspect infrastructure:
   - GitHub workflows
   - scripts
   - Makefile and project configuration
5. Synthesize findings into critical, significant, and minor issues plus per-module analysis.
6. Commit, push, and emit the requested completion event.

## Review Standards

- Prefer functional and architectural issues over style-only comments.
- Call out missing validation, silent failures, weak tests, insecure defaults, and dead or misleading code.
- Treat documented intent as a claim to verify against implementation, not as proof that behavior is correct.
