# iOS simulator runbook

## Preconditions

- macOS host
- Flutter installed and working
- An available iOS simulator runtime in Xcode
- Backend dependencies installed

## Standard flow

1. Confirm a simulator runtime exists with `xcrun simctl list devices available`.
2. Start the backend with `bash scripts/run-api.sh`.
3. Run the simulator test flow with `API_BASE_URL=http://127.0.0.1:8000 bash scripts/run-ios-sim-tests.sh`.

## Current repository caveat

- On the current local machine, `xcrun simctl list devices available` returned no available iOS runtime, so the integration test could not be executed locally.
- The existing Flutter integration test requires a supported simulator/device and a running backend.

## Failure handling

- If the app cannot reach the backend, verify `API_BASE_URL` and confirm `GET /health` responds.
- If no simulator is detected, install or enable an iOS runtime in Xcode before retrying.
