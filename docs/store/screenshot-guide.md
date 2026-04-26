# Curator Store Screenshot Guide

`큐레이터`의 App Store / Play Store 스크린샷을 같은 기준으로 다시 찍기 위한 수동 캡처 가이드다.

기준 문서:

- `docs/store/app-store-listing.md`
- `docs/store/play-store-listing.md`
- `docs/runbooks/ios-simulator-core-pages.md`
- Apple App Store Connect screenshot specs: <https://developer.apple.com/help/app-store-connect/reference/screenshot-specifications>
- Google Play preview asset specs: <https://support.google.com/googleplay/android-developer/answer/1078870>

## Locale And Capture Defaults

- 언어: `한국어`
- 지역: `대한민국`
- Appearance: `Light`
- Dynamic Type: 기본값
- 기기 방향: `세로(portrait)`만 사용
- 상태: 알림 배너, 통화 표시, 저전력 모드, 디버그 오버레이 없이 촬영
- 데이터 상태:
  - 온보딩은 `새 설치 상태`
  - 홈, 질문, 답변은 `데모 데이터 14건 로드 상태`
  - 파일 가져오기는 샘플 파일 1건 이상 가져온 뒤 촬영
  - 캘린더는 최근 30일 안의 테스트 일정 1건 이상 동기화한 뒤 촬영 권장

## Required Simulator Devices

### Primary App Store Device

- Simulator name: `iPhone 15 Pro Max`
- CoreSimulator device type: `com.apple.CoreSimulator.SimDeviceType.iPhone-15-Pro-Max`
- 용도:
  - App Store 메인 제출본
  - Play Store raw capture source
- Raw screenshot size: `1290 x 2796`

### Secondary App Store Device

- Simulator name: `iPhone 8`
- CoreSimulator device type: `com.apple.CoreSimulator.SimDeviceType.iPhone-8`
- 용도:
  - App Store 4.7" 보조 제출본
- Raw screenshot size: `750 x 1334`

## Required Image Dimensions

### App Store

- `iPhone 15 Pro Max`: `1290 x 2796` PNG
- `iPhone 8`: `750 x 1334` PNG
- 업로드 형식: `.png`, `.jpg`, `.jpeg`

### Play Store

- 형식: `PNG` 또는 `24-bit JPG` without alpha
- Feature graphic: `1024 x 500`
- Phone screenshots:
  - 허용 범위: 최소 `320 px`, 최대 `3840 px`
  - 긴 변은 짧은 변의 `2배 이하`
  - 권장 세로형: `1080 x 1920`

### Important Play Store Note

`iPhone 15 Pro Max` raw screenshot `1290 x 2796`는 비율이 `2:1`을 초과하므로 Play Store에 그대로 업로드하지 않는다.

Play Store용 final 이미지는 다음 순서로 만든다.

1. `1290 x 2796` raw screenshot를 세로 중앙 기준으로 `1290 x 2293`까지 crop
2. `1080 x 1920`으로 export
3. 텍스트와 핵심 UI가 잘리지 않았는지 확인

## Output Paths And Naming

App Store 6.7" final:

- `captures/store/app-store/ko-KR/iphone-15-pro-max/01-onboarding.png`
- `captures/store/app-store/ko-KR/iphone-15-pro-max/02-home-dashboard.png`
- `captures/store/app-store/ko-KR/iphone-15-pro-max/03-question-input.png`
- `captures/store/app-store/ko-KR/iphone-15-pro-max/04-curation-result.png`
- `captures/store/app-store/ko-KR/iphone-15-pro-max/05-settings-runtime-privacy.png`
- `captures/store/app-store/ko-KR/iphone-15-pro-max/06-file-import.png`
- `captures/store/app-store/ko-KR/iphone-15-pro-max/07-calendar-sync.png`

App Store 4.7" final:

- `captures/store/app-store/ko-KR/iphone-8/01-onboarding.png`
- `captures/store/app-store/ko-KR/iphone-8/02-home-dashboard.png`
- `captures/store/app-store/ko-KR/iphone-8/03-question-input.png`
- `captures/store/app-store/ko-KR/iphone-8/04-curation-result.png`
- `captures/store/app-store/ko-KR/iphone-8/05-settings-runtime-privacy.png`
- `captures/store/app-store/ko-KR/iphone-8/06-file-import.png`
- `captures/store/app-store/ko-KR/iphone-8/07-calendar-sync.png`

Play Store raw source captures:

- `captures/store/play-store/ko-KR/raw-iphone-15-pro-max/01-onboarding.png`
- `captures/store/play-store/ko-KR/raw-iphone-15-pro-max/02-home-first-entry.png`
- `captures/store/play-store/ko-KR/raw-iphone-15-pro-max/03-question-input.png`
- `captures/store/play-store/ko-KR/raw-iphone-15-pro-max/04-curation-result.png`
- `captures/store/play-store/ko-KR/raw-iphone-15-pro-max/05-settings-runtime-badge.png`
- `captures/store/play-store/ko-KR/raw-iphone-15-pro-max/06-file-import-state.png`
- `captures/store/play-store/ko-KR/raw-iphone-15-pro-max/07-calendar-sync-state.png`
- `captures/store/play-store/ko-KR/raw-iphone-15-pro-max/08-delete-confirmation.png`

Play Store final exports:

- `captures/store/play-store/ko-KR/final/01-onboarding-1080x1920.png`
- `captures/store/play-store/ko-KR/final/02-home-first-entry-1080x1920.png`
- `captures/store/play-store/ko-KR/final/03-question-input-1080x1920.png`
- `captures/store/play-store/ko-KR/final/04-curation-result-1080x1920.png`
- `captures/store/play-store/ko-KR/final/05-settings-runtime-badge-1080x1920.png`
- `captures/store/play-store/ko-KR/final/06-file-import-state-1080x1920.png`
- `captures/store/play-store/ko-KR/final/07-calendar-sync-state-1080x1920.png`
- `captures/store/play-store/ko-KR/final/08-delete-confirmation-1080x1920.png`

규칙:

- 파일명은 항상 `두 자리 순번 + 화면 slug`를 쓴다.
- 언어별 폴더는 `ko-KR`로 고정한다.
- App Store와 Play Store는 폴더를 분리한다.
- Play Store는 `raw`와 `final`을 분리한다.

## Store Screen Inventory

### App Store Screens

1. 온보딩
2. 홈 대시보드
3. 질문 입력 상태
4. 큐레이션 결과 상세
5. 설정의 프라이버시 및 런타임 상태
6. 파일 가져오기
7. 캘린더 가져오기

### Play Store Screens

1. 온보딩 화면
2. 홈 화면 첫 진입
3. 질문 입력
4. 큐레이션 결과 카드
5. 설정 화면의 런타임 상태 배지
6. 파일 가져오기 화면 또는 파일 선택 후 상태
7. 캘린더 동기화 상태 화면
8. 데이터 삭제 확인 흐름

## Simulator Capture Workflow

권장 실행:

```bash
./scripts/capture-screenshots.sh appstore67
./scripts/capture-screenshots.sh appstore47
./scripts/capture-screenshots.sh play
```

스크립트는 다음을 자동으로 처리한다.

- 대상 simulator 확인 또는 생성
- simulator boot
- `mobile/`에서 `flutter pub get`
- iOS simulator debug build
- 앱 설치 및 실행
- 샘플 가져오기 파일 생성
- 각 스크린샷 단계별 수동 안내 출력
- 현재 보이는 화면을 지정 경로로 저장

## Per-Screenshot Steps

### 1. Onboarding

대상:

- App Store `01-onboarding`
- Play Store `01-onboarding`

준비:

- 새 설치 상태로 앱 실행
- 첫 onboarding 페이지 `큐레이터 시작하기`가 보일 때까지 대기

촬영 포인트:

- 상단 브랜드 아이콘
- `큐레이터 시작하기`
- 첫 hero copy `큐\n레이터`

단계:

1. 앱이 처음 실행되면 loading을 지나 onboarding 첫 페이지에서 멈춘다.
2. 한국어 텍스트가 모두 자연스럽게 보이는지 확인한다.
3. 시스템 권한 팝업이 뜨면 닫고 다시 정리한다.
4. capture한다.

### 2. Home Dashboard / First Entry

대상:

- App Store `02-home-dashboard`
- Play Store `02-home-first-entry`

준비:

- onboarding 마지막 페이지로 이동
- `데모 데이터 함께 시작하기` 체크
- `시작하기` 탭
- 홈 화면 렌더링 완료 대기

촬영 포인트:

- `큐레이터`
- `오늘의 질문`
- 최근 대화 또는 연결된 기록 영역

단계:

1. onboarding 마지막 페이지에서 demo data를 켠다.
2. 홈 진입 후 상단 인사말과 오늘의 질문 카드가 함께 보이도록 한다.
3. 화면이 빈 상태가 아니라 데모 데이터가 반영된 상태인지 확인한다.
4. capture한다.

### 3. Question Input

대상:

- App Store `03-question-input`
- Play Store `03-question-input`

준비:

- 홈에서 `오늘의 질문` 카드 탭
- 질문 화면 진입

질문 문구:

- `나 요즘 왜 이렇게 무기력하지?`

촬영 포인트:

- `질문하기`
- 입력창에 질문이 들어간 상태
- 시간 범위 chip이 자연스럽게 보이는 상태

단계:

1. 입력창에 예시 질문을 붙여넣거나 직접 입력한다.
2. 키보드가 화면을 너무 많이 가리면 살짝 내려 UI를 정리한다.
3. submit 전 상태에서 capture한다.

### 4. Curation Result

대상:

- App Store `04-curation-result`
- Play Store `04-curation-result`

준비:

- question input 화면에서 submit
- answer 화면의 stream 애니메이션이 끝날 때까지 3~5초 대기

촬영 포인트:

- 답변 본문
- `참고한 기록`
- supporting record 카드

단계:

1. 질문 제출 후 `생각 중…` 상태가 끝날 때까지 기다린다.
2. 답변 문단과 supporting record 카드가 함께 보이게 위치를 맞춘다.
3. capture한다.

### 5. Settings Runtime / Privacy

대상:

- App Store `05-settings-runtime-privacy`
- Play Store `05-settings-runtime-badge`

준비:

- 홈 또는 하단 탭에서 설정 진입
- settings 상단에 머문다

촬영 포인트:

- 설정 상단 요약 문장
- `사용 방식`
- `온디바이스 우선`
- `현재 모드`

단계:

1. 설정 최상단에서 상단 summary와 `사용 방식` 섹션이 한 화면에 들어오게 맞춘다.
2. `질문과 기록을 기기 안에서 먼저 읽습니다.` 문구가 보이게 한다.
3. capture한다.

### 6. File Import

대상:

- App Store `06-file-import`
- Play Store `06-file-import-state`

준비:

- 스크립트가 만든 샘플 파일:
  - `captures/store/support/sample-record.txt`
- 설정의 데이터 상태 섹션으로 이동
- `파일 가져오기`를 통해 샘플 파일 1건 import 권장

촬영 포인트:

- `파일 가져오기`
- 저장된 기록 수 또는 가져오기 기록 변화
- 파일 import가 실제 기능임을 보여 주는 상태

단계:

1. `파일 가져오기`를 눌러 샘플 파일을 선택한다.
2. import 완료 메시지를 확인한다.
3. 데이터 상태 또는 가져오기 기록이 보이도록 스크롤 위치를 맞춘다.
4. capture한다.

### 7. Calendar Sync

대상:

- App Store `07-calendar-sync`
- Play Store `07-calendar-sync-state`

준비:

- Simulator Calendar 앱에서 최근 30일 안의 테스트 이벤트 1건 생성 권장
- 예시 제목: `산책 30분`
- Curator 설정으로 돌아가 `캘린더 동기화` 활성화
- 권한 허용 후 `지금 동기화`

촬영 포인트:

- `캘린더 동기화`
- 권한, 상태, 마지막 동기화, 가져온 일정
- 가능하면 imported count가 1건 이상인 상태

단계:

1. 권한 허용 후 동기화를 한 번 완료한다.
2. `권한`, `상태`, `마지막 동기화`, `가져온 일정`이 보이도록 맞춘다.
3. capture한다.

### 8. Delete Confirmation

대상:

- Play Store `08-delete-confirmation`

준비:

- 설정의 데이터 상태 섹션으로 이동
- `모든 데이터 삭제` 탭

촬영 포인트:

- 확인 dialog 전체
- 삭제 대상 설명 문구
- `취소` / `삭제` 액션

단계:

1. 삭제 dialog가 뜨면 배경이 너무 어둡게 가려지지 않는지 확인한다.
2. dialog 문구가 잘리지 않게 둔다.
3. capture한다.
4. 실제 삭제가 필요 없으면 `취소`를 탭한다.

## Manual Korean Locale Setup

스크립트는 locale을 강제 변경하지 않는다. 촬영 전 simulator에서 직접 맞춘다.

1. Simulator에서 `Settings` 앱 실행
2. `General > Language & Region`
3. iPhone Language를 `한국어`로 변경
4. Region을 `대한민국`으로 설정
5. 필요하면 앱을 다시 실행

## Post-Processing Checklist

### App Store

- 원본 PNG 유지
- 여백 추가, 기기 프레임 추가, 과한 overlay 추가 금지
- 두 device bucket 모두 같은 순서 유지

### Play Store

- raw 파일에서 final `1080 x 1920` export 생성
- alpha 제거
- 첫 4장은 핵심 UX를 우선 배치
- `08-delete-confirmation`은 마지막 슬롯 유지 권장

## Recommended Upload Order

### App Store

1. onboarding
2. home dashboard
3. question input
4. curation result
5. settings runtime/privacy
6. file import
7. calendar sync

### Play Store

1. onboarding
2. home first entry
3. question input
4. curation result
5. settings runtime badge
6. file import state
7. calendar sync state
8. delete confirmation
