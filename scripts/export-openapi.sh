#!/usr/bin/env bash
set -euo pipefail
if [[ -z "${PYTHON_BIN:-}" ]]; then
  for candidate in python3 python; do
    if command -v "$candidate" >/dev/null 2>&1 &&
      "$candidate" -c 'import sys; import fastapi; raise SystemExit(0 if sys.version_info.major == 3 else 1)' >/dev/null 2>&1; then
      PYTHON_BIN="$(command -v "$candidate")"
      break
    fi
  done
fi

: "${PYTHON_BIN:?A Python 3 interpreter with FastAPI installed is required to export OpenAPI.}"
"$PYTHON_BIN" - <<'PY'
import json
from backend.app.main import app
with open('backend/openapi.json', 'w', encoding='utf-8') as f:
    json.dump(app.openapi(), f, ensure_ascii=False, indent=2)
PY
