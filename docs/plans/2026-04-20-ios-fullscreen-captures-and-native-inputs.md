## Summary

- Replace app-surface-only screenshots with full iOS simulator device screenshots so the status bar is naturally included.
- Remove the visual bottom gap between the product bottom bar and the physical device edge by fixing safe-area handling.
- Restyle ask/follow-up input boxes to feel more native on iOS.

## Scope

- `mobile/lib/src/presentation/**`
- `mobile/test_driver/**`
- `mobile/integration_test/**`
- `docs/runbooks/**`
- `website/captures/**`
- `website/*.md`

## Steps

1. Inspect current screenshots and identify whether each issue comes from capture pipeline or app layout.
2. Update bottom navigation and answer follow-up bar safe-area layout so the background extends to the device bottom.
3. Restyle ask/follow-up text inputs to use more iOS-native field behavior and appearance.
4. Update the iOS screenshot driver to capture full simulator device images with a deterministic status bar.
5. Regenerate website captures and update docs that describe the capture lane.

## Validation

- `flutter analyze`
- `flutter test`
- `flutter build ios --simulator --no-codesign`
- `flutter drive --driver=test_driver/website_capture_driver.dart --target=integration_test/ios_core_pages_capture_test.dart -d <simulator-id>`
- `./scripts/validate-docs.sh`

## Risks

- Full-device simulator screenshots depend on a booted simulator and `xcrun simctl`.
- The ask screen can auto-focus the field and surface the iOS keyboard, so capture timing must explicitly dismiss focus when needed.
