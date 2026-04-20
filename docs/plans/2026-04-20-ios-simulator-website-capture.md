## Summary

- Generate deterministic iOS simulator screenshots for core mobile pages and store them under `website/`.
- If screenshot capture reveals runtime issues, fix the root cause and update `docs/runbooks/ios-simulator-core-pages.md`.
- Add markdown/design docs under `website/` for the landing page and App Store page so Codex/harness can reuse them.

## Scope

- `mobile/integration_test/**`
- `mobile/test_driver/**`
- `docs/runbooks/**`
- `website/**`

## Implementation Steps

1. Add a dedicated iOS simulator screenshot integration test with stable provider overrides and deterministic sample data.
2. Add a dedicated `flutter drive` driver that saves `takeScreenshot()` bytes into `website/captures/ios-simulator/core/`.
3. Run the capture flow on the booted iOS simulator and verify each target screen is produced.
4. If capture fails, fix the app/test harness and reflect any procedural changes in `docs/runbooks/ios-simulator-core-pages.md`.
5. Write landing page and App Store markdown/design docs under `website/` referencing the captured screens.

## Validation

- `flutter analyze`
- `flutter test`
- `flutter build ios --simulator --no-codesign`
- `flutter drive --driver=test_driver/website_capture_driver.dart --target=integration_test/ios_core_pages_capture_test.dart -d <simulator-id>`
- `./scripts/validate-docs.sh`

## Risks

- Simulator screenshot capture can be flaky if the UI depends on live storage or plugin state.
- The answer screen streams text, so screenshot timing must wait for the final non-loading state.
- Website docs should reference only checked-in assets and avoid environment-specific assumptions.
