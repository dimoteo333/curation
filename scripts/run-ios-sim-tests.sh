#!/usr/bin/env bash
set -euo pipefail

cd mobile

API_BASE_URL="${API_BASE_URL:-http://127.0.0.1:8000}"
SIMULATOR_ID="${IOS_SIMULATOR_ID:-$(xcrun simctl list devices booted | awk -F '[()]' '/Booted/{print $2; exit}')}"

if [[ -z "$SIMULATOR_ID" ]]; then
  echo "No booted iOS simulator found." >&2
  exit 1
fi

curl --fail --silent --show-error "${API_BASE_URL}/health" >/dev/null

flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/remote_harness_test.dart \
  -d "$SIMULATOR_ID" \
  --dart-define=CURATION_MODE=remote \
  --dart-define=API_BASE_URL="$API_BASE_URL"

flutter test integration_test/full_pipeline_test.dart
