#!/usr/bin/env bash
set -euo pipefail

bash scripts/export-openapi.sh

if ! git diff --exit-code -- backend/openapi.json; then
  echo "OpenAPI drift detected. Re-export backend/openapi.json and commit the updated contract."
  exit 1
fi

echo "OpenAPI drift check passed"
