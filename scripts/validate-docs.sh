#!/usr/bin/env bash
set -euo pipefail

required_files=(
  "AGENTS.md"
  "docs/architecture/mobile.md"
  "docs/architecture/backend.md"
  "docs/architecture/contracts.md"
  "docs/architecture/mobile-ondevice-llm.md"
  "docs/contributing.md"
  "docs/runbooks/guardrails.md"
  "backend/openapi.json"
  ".pre-commit-config.yaml"
  ".github/workflows/docs-guard.yml"
)

for f in "${required_files[@]}"; do
  test -f "$f"
done

grep -q "backend/openapi.json" docs/architecture/contracts.md
grep -q "체크리스트" docs/contributing.md
grep -q "우회 방지 전략" docs/runbooks/guardrails.md
grep -q "docs-guard" .github/workflows/docs-guard.yml

echo "docs validation passed"
