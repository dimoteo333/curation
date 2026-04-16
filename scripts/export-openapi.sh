#!/usr/bin/env bash
set -euo pipefail
PYTHON_BIN="${PYTHON_BIN:-$(command -v python3 || command -v python)}"
"$PYTHON_BIN" - <<'PY'
import json
from backend.app.main import app
with open('backend/openapi.json', 'w', encoding='utf-8') as f:
    json.dump(app.openapi(), f, ensure_ascii=False, indent=2)
PY
