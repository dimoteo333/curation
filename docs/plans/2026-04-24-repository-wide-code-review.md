# Repository-Wide Code Review Plan

Date: 2026-04-24
Scope: mobile, backend, tests, scripts, CI, and repository configuration

## Goals

- Review the implemented code across the Flutter mobile client and FastAPI backend.
- Identify concrete issues in correctness, security, performance, architecture, testing, and delivery workflow.
- Produce a prioritized Korean review with file and line references.

## Approach

1. Read the required architecture, contract, contributing, and guardrail documents.
2. Map the repository structure and identify primary entrypoints, build scripts, and workflow files.
3. Review mobile source, state, persistence, native bridge, and tests.
4. Review backend routers, services, repositories, schemas, and tests.
5. Review CI/CD workflows and repository scripts for validation gaps.
6. Consolidate findings into prioritized categories with concrete references.

## Review Standards

- Prioritize bugs, regressions, security/privacy issues, performance bottlenecks, and maintainability risks.
- Treat documentation as intent only and verify behavior against implementation.
- Call out missing or weak tests when risk is not covered by automation.
