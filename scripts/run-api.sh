#!/usr/bin/env bash
set -euo pipefail

PYTHON_BIN="${PYTHON_BIN:-$(command -v python3 || command -v python)}"

"$PYTHON_BIN" -m uvicorn backend.app.main:app --host 127.0.0.1 --port 8000
