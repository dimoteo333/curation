# Curation Website Assets

이 디렉터리는 landing page, App Store page, 그리고 harness 재사용용 iOS simulator 산출물을 함께 보관한다.

## Captures

Core simulator captures:

- `captures/ios-simulator/core/loading.png`
- `captures/ios-simulator/core/onboarding.png`
- `captures/ios-simulator/core/home.png`
- `captures/ios-simulator/core/today-question.png`
- `captures/ios-simulator/core/answer.png`
- `captures/ios-simulator/core/memory-sheet.png`
- `captures/ios-simulator/core/timeline.png`
- `captures/ios-simulator/core/settings.png`

생성 커맨드:

```sh
cd mobile
flutter drive \
  --driver=test_driver/website_capture_driver.dart \
  --target=integration_test/ios_core_pages_capture_test.dart \
  -d <ios-simulator-id>
```

## Docs

- `landing-page.md`: curation landing page IA, copy skeleton, section order
- `app-store-page.md`: App Store listing copy, screenshot narrative, metadata draft
- `design/visual-direction.md`: web/app-store 공용 비주얼 방향과 asset usage rule

## Notes for Codex

- 캡쳐는 deterministic provider override 기반이라 앱 실데이터 없이 재생성할 수 있다.
- 문서의 screenshot reference는 모두 `captures/ios-simulator/core/` 기준 상대경로를 사용한다.
- 이 폴더에는 환경 파일을 두지 않는다.
