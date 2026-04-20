# iOS simulator core-page test runbook

## Purpose

Codex나 다른 harness가 iOS simulator에서 큐레이터의 핵심 화면을 일관되게 검증할 수 있도록, 진입 조건과 안정적인 selector를 한 문서에 정리한다.

## Scope

- startup loading
- onboarding
- home
- ask
- answer
- memory sheet
- timeline
- settings

## Preconditions

- macOS host
- Xcode와 사용 가능한 iOS simulator runtime
- `cd mobile && flutter pub get` 완료
- 기본 smoke 검증:
  - `cd mobile && flutter analyze`
  - `cd mobile && flutter test`
  - `cd mobile && flutter build ios --simulator --no-codesign`

## Codex usage rules

- 가능한 경우 `find.byKey`를 우선 사용한다.
- key가 없는 화면은 고정 한국어 텍스트를 anchor로 사용한다.
- 홈/타임라인/설정 진입은 하단 탭 라벨 텍스트를 우선 사용한다.
- answer와 memory sheet는 비동기 렌더링이 있으므로 화면 전환 직후 한 번 더 `pumpAndSettle` 또는 wait를 둔다.
- 공유 import, DB recovery, native bridge readiness는 이 문서의 core-page 범위 밖이다. 별도 runbook으로 다룬다.

## Standard launch profiles

### Profile A. Fresh install

용도:
- loading
- onboarding
- first-run home empty state

권장 상태:
- 앱 삭제 후 재설치 또는 simulator에서 앱 데이터 초기화
- `SharedPreferences`에 `app.onboarding_completed` 없음

### Profile B. Onboarded empty state

용도:
- home empty state
- settings

권장 상태:
- `app.onboarding_completed = true`
- local record count = 0

### Profile C. Onboarded seeded state

용도:
- ask
- answer
- memory sheet
- timeline

권장 상태:
- `app.onboarding_completed = true`
- 질문 가능한 시드/로컬 레코드가 존재

## Stable selectors

### Keys

- `homeBrandLogo`
- `openSettingsButton`
- `todayAskCard`
- `homeEmptyStateCard`
- `homeImportDataButton`
- `homeLoadDemoDataButton`
- `questionTextField`
- `submitQuestionButton`
- `onboardingSkipButton`
- `onboardingNextButton`
- `completeOnboardingButton`
- `settingsCalendarToggle`
- `settingsCalendarSyncButton`
- `settingsGoogleCalendarNoteButton`
- `settingsImportButton`
- `settingsLoadDemoDataButton`
- `settingsClearDataButton`
- `settingsNotesImportButton`
- `settingsNotesGuideButton`
- `developerRuntimeToggleButton`
- `llmModelPathField`
- `embedderModelPathField`
- `saveModelPathsButton`
- `privacyPolicyButton`
- `showLicenseButton`
- `localDataRetryOnlyButton`
- `localDataRecoveryRetryButton`
- `localDataRecoveryResetButton`

### Text anchors

- `로컬 데이터를 준비하는 중입니다`
- `기기 안의 기록 저장소를 안전하게 확인하고 있습니다.`
- `큐레이터 시작하기`
- `큐레이터`
- `오늘의 질문`
- `최근 대화`
- `연결된 기록`
- `질문하기`
- `참고한 기록`
- `답변이 도움이 되었나요?`
- `원문 열기`
- `타임라인`
- `설정`
- `사용 방식`
- `캘린더`

## Core-page scenarios

### 1. Startup loading

Precondition:
- Profile A

Entry:
- 앱 실행 직후 첫 화면

Assertions:
- 텍스트 `로컬 데이터를 준비하는 중입니다`
- 텍스트 `기기 안의 기록 저장소를 안전하게 확인하고 있습니다.`

Notes:
- 이 화면은 짧게 지나갈 수 있으므로 첫 screenshot 포인트로 쓰기보다 “보이면 확인” 방식이 적합하다.

### 2. Onboarding

Precondition:
- Profile A

Entry:
- startup loading 다음

Assertions:
- 텍스트 `큐레이터 시작하기`
- key `onboardingSkipButton`
- key `onboardingNextButton`

Exit action:
1. `onboardingSkipButton` 탭
2. 마지막 페이지에서 `completeOnboardingButton` 탭

Expected after exit:
- home 또는 empty home으로 진입

### 3. Home

Precondition:
- Profile B 또는 C

Entry:
- 앱 실행 후 기본 landing tab

Assertions:
- key `homeBrandLogo`
- key `openSettingsButton`
- 텍스트 `오늘의 질문`
- 텍스트 `최근 대화`
- 텍스트 `연결된 기록`

Profile B extra assertions:
- key `homeEmptyStateCard`
- key `homeImportDataButton`
- key `homeLoadDemoDataButton`

Primary action:
- key `todayAskCard` 탭 시 ask 화면으로 이동

### 4. Ask

Precondition:
- Profile C

Entry:
- home의 `todayAskCard` 탭

Assertions:
- 텍스트 `질문하기`
- key `questionTextField`
- key `submitQuestionButton`

Primary action:
1. `questionTextField`에 질문 입력
   - 예시: `나 요즘 왜 이렇게 무기력하지?`
2. `submitQuestionButton` 탭

Expected after action:
- answer 화면으로 이동

### 5. Answer

Precondition:
- Profile C
- ask 화면에서 질문 제출 완료

Assertions:
- 텍스트 `참고한 기록`
- 텍스트 `답변이 도움이 되었나요?`
- supporting record 카드가 하나 이상 보임

Codex wait rule:
- 답변은 paragraph reveal animation이 있으므로 제출 후 3~5초 범위의 wait 또는 반복 pump를 허용한다.

Primary action:
- supporting record 카드 첫 항목 탭

Expected after action:
- memory sheet가 bottom sheet로 열린다

### 6. Memory sheet

Precondition:
- answer 또는 timeline에서 record open 완료

Assertions:
- 텍스트 `원문 열기`
- record title 또는 source badge가 보임

Optional assertions:
- 위치 메타데이터가 있는 fixture에서는 예: `서울 · 합정동`

Exit action:
- 우상단 close 버튼 또는 sheet dismiss gesture

### 7. Timeline

Precondition:
- Profile C

Entry:
- 하단 탭 `타임라인` 탭

Assertions:
- 텍스트 `타임라인`
- record section heading이 하나 이상 보임

Primary action:
1. 리스트에서 visible record title 탭
2. memory sheet 오픈 확인

Expected after action:
- 텍스트 `원문 열기`

### 8. Settings

Precondition:
- Profile B 또는 C

Entry options:
- home의 key `openSettingsButton`
- 하단 탭 `설정`

Assertions:
- 텍스트 `설정`
- 텍스트 `사용 방식`
- 텍스트 `캘린더`
- key `settingsImportButton`
- key `settingsNotesImportButton`
- key `privacyPolicyButton`

Optional developer assertions:
- key `developerRuntimeToggleButton`
- key `llmModelPathField`
- key `embedderModelPathField`
- key `saveModelPathsButton`

## Recommended harness order

1. loading
2. onboarding
3. home
4. ask
5. answer
6. memory sheet
7. timeline
8. settings

이 순서는 가장 적은 state reset으로 핵심 화면을 모두 순회할 수 있다.

## Automated capture lane

실제 simulator screenshot을 workspace에 저장해야 할 때는 아래 lane을 사용한다.

Command:
- `cd mobile && flutter drive --driver=test_driver/website_capture_driver.dart --target=integration_test/ios_core_pages_capture_test.dart -d <simulator-id>`

Outputs:
- `website/captures/ios-simulator/core/loading.png`
- `website/captures/ios-simulator/core/onboarding.png`
- `website/captures/ios-simulator/core/home.png`
- `website/captures/ios-simulator/core/today-question.png`
- `website/captures/ios-simulator/core/answer.png`
- `website/captures/ios-simulator/core/memory-sheet.png`
- `website/captures/ios-simulator/core/timeline.png`
- `website/captures/ios-simulator/core/settings.png`

Harness notes:
- 이 lane은 실데이터 대신 deterministic provider override를 사용한다.
- answer와 memory sheet는 실제 질문 제출 플로우를 통과한 뒤 캡쳐된다.
- Codex가 screenshot byte를 직접 저장하므로 별도 수동 export step이 없다.

## Existing automated coverage to reuse

- `mobile/integration_test/app_lifecycle_test.dart`
  - fresh install, onboarding, recovery, home 진입
- `mobile/integration_test/tab_screenshots_test.dart`
  - home landing과 `homeBrandLogo` 존재 확인
- `mobile/integration_test/ios_core_pages_capture_test.dart`
  - website용 core-page screenshot 생성과 selector 검증
- `mobile/test/widget_test.dart`
  - home -> ask -> answer -> memory -> settings -> timeline 흐름
- `mobile/test/onboarding_test.dart`
  - onboarding CTA와 first-run state
- `mobile/test/settings_screen_test.dart`
  - settings 핵심 섹션

## Failure triage

- loading에서 멈춤:
  - local DB init 또는 secure storage 상태를 먼저 확인한다.
  - `localDataRecovery*` 버튼 노출 여부를 본다.
- answer가 안 뜸:
  - seeded/local records 존재 여부 확인
  - `questionTextField` 입력 후 submit이 실제 탭됐는지 확인
- memory sheet가 안 뜸:
  - supporting record 카드가 모두 렌더된 뒤 탭했는지 확인
- settings에서 import 버튼이 안 보임:
  - wrong tab 여부 확인
  - narrow viewport에서 scroll 필요 여부 확인

## Codex verification checklist

- 문서에 적은 key selector는 실제 코드에 존재해야 한다.
- 문서에 적은 text anchor는 실제 UI 문자열과 일치해야 한다.
- 최소 1개 iOS simulator integration test가 이 문서의 selector를 실제로 사용해야 한다.
