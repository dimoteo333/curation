#!/usr/bin/env bash
set -euo pipefail

for f in docs/architecture/mobile.md docs/architecture/backend.md docs/architecture/contracts.md AGENTS.md; do
  test -f "$f"
done

grep -q "backend/openapi.json" docs/architecture/contracts.md

echo "docs validation passed"