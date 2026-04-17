# 2026-04-17 Sprint 6 Plan

## Scope

- Android 빌드 구성을 검증하고 MediaPipe/LiteRT 브릿지가 실제로 컴파일 가능한 상태인지 확인한다.
- iOS와 Android의 온디바이스 런타임 상태 응답, 오류 코드, 폴백 동작을 일치시킨다.
- 현재 저장소 기준으로 네이티브 텍스트 임베딩은 두 플랫폼 모두 비활성화하고 Dart 의미 임베딩 폴백을 유지한다.
- 백엔드 OpenAPI 계약은 변경하지 않는다.

## Goals

- `mobile/android/app/build.gradle.kts`에서 Android namespace, `applicationId`, 최소 SDK, 의존성 버전 고정, release 난독화 규칙을 점검한다.
- Android Kotlin 브릿지가 MediaPipe GenAI API와 맞는 방식으로 `LlmInference`만 사용하도록 정리한다.
- `embed` 메서드는 iOS와 동일하게 `embedder_unavailable` 오류를 반환하고, 상태 응답은 부분 준비 상태를 명확히 드러낸다.
- 공통 Dart 브릿지에서 두 플랫폼의 상태와 예외를 같은 방식으로 해석한다.
- 문서에 iOS/Android 현재 지원 범위와 Android 수동 검증 체크를 반영한다.

## Design

### Native bridge contract

- 채널 이름과 메서드 이름은 유지한다.
- 상태 응답은 두 플랫폼 모두 아래 키를 포함한다.
  - `llmReady`
  - `embedderReady`
  - `runtime`
  - `message`
  - `platform`
  - `llmModelConfigured`
  - `embedderModelConfigured`
  - `llmModelAvailable`
  - `embedderModelAvailable`
  - `fallbackActive`
  - `lastError`
  - `lastPrepareDurationMs`
- 네이티브 텍스트 임베딩은 양 플랫폼 모두 미지원 상태로 통일한다.
  - `embed` 호출 시 `embedder_unavailable`
  - `generate` 미지원 시 `llm_unavailable`
  - 빈 프롬프트는 `invalid_prompt`
  - 빈 텍스트는 `invalid_text`

### Android build

- MediaPipe GenAI용 최소 SDK는 24 이상으로 유지한다.
- Android 의존성은 동적 버전 없이 고정 버전만 사용한다.
- release 빌드에는 `minifyEnabled`와 `shrinkResources`를 켜고, MediaPipe/LiteRT 네이티브 라이브러리를 보존하는 규칙을 추가한다.
- Android manifest에는 원격 하네스용 `INTERNET`과 파일 import용 `READ_EXTERNAL_STORAGE`/`READ_MEDIA_*` 가드를 명시한다.

## Risks

- Flutter/AGP/Kotlin 조합과 MediaPipe AAR 조합이 충돌하면 Android 컴파일 단계에서만 드러날 수 있다.
- 임베딩을 네이티브에서 비활성화하면 상태 메시지와 폴백 배지가 이를 정확히 설명해야 한다.
- release shrinker 규칙이 부족하면 Android release 빌드는 통과해도 실제 기기에서 native library 로딩이 실패할 수 있다.

## Validation

- `cd mobile && flutter pub get`
- `cd mobile && flutter analyze`
- `cd mobile && flutter test`
- `cd mobile && flutter build apk --debug`
- `./scripts/check-native-dependency-pins.sh --strict`
- `./scripts/check-release-signing.sh`
- `./scripts/validate-docs.sh`

## Progress

- Android native bridge를 `tasks-genai` 0.10.21의 실제 Kotlin API에 맞게 정리하고, 네이티브 텍스트 임베딩은 양 플랫폼 모두 미지원으로 통일했다.
- Android release shrinker 설정과 MediaPipe/TFLite keep rules를 추가했다.
- Android manifest 권한과 launch background 리소스 오류를 정리해 debug APK 빌드가 통과하도록 수정했다.
- Dart bridge, iOS bridge, provider wiring을 함께 갱신해 상태 응답과 오류 메시지를 공통 포맷으로 맞췄다.
- 브릿지 상태 정규화와 공통 오류 메시지 처리를 검증하는 Flutter 테스트를 추가했다.

## Validation Result

- `cd mobile && flutter pub get`
- `cd mobile && flutter analyze`
- `cd mobile && flutter test`
- `cd mobile && JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build apk --debug`
- `cd mobile && JAVA_HOME=/opt/homebrew/opt/openjdk@17 flutter build ios --simulator --no-codesign`
- `python3 -m pytest backend/tests`
- `python3 -m ruff check backend/app backend/tests`
- `python3 -m mypy backend/app`
- `./scripts/export-openapi.sh`
- `./scripts/check-native-dependency-pins.sh --strict`
- `./scripts/check-release-signing.sh`
- `./scripts/validate-docs.sh`
