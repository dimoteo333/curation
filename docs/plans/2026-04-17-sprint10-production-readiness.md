# 2026-04-17 Sprint 10 Plan

## Scope

- 모바일 Android/iOS 릴리스 빌드 구성을 프로덕션 준비 수준으로 정리한다.
- 스토어 메타데이터, 릴리스 CI/CD, 버전 관리 문서를 추가한다.
- 백엔드 HTTP 계약은 변경하지 않는다.

## Goals

- Android `build.gradle.kts`에 debug/release signing 분리와 환경 기반 release signing 구성을 추가한다.
- Android release shrinker가 MediaPipe, SQLite, Flutter 런타임을 유지하도록 ProGuard 규칙을 정리한다.
- iOS 프로젝트의 bundle identifier, 버전, deployment target을 현재 배포 정책(iOS 16+)에 맞게 정렬한다.
- iOS archive export용 `exportOptions.plist`와 signing runbook을 추가한다.
- PR 게이트에서 Android/iOS 비서명 빌드 검증을 수행하고, 태그 기반 release workflow를 추가한다.
- `pubspec.yaml`, Android, iOS 버전을 `0.1.0+1`로 일치시킨다.
- Sprint 1-10 요약 `CHANGELOG.md`를 추가한다.

## Design

### Android signing

- debug 빌드는 저장소 내 개발용 debug keystore를 사용한다.
- release 빌드는 환경 변수 우선, `local.properties` 보조로 keystore 경로와 자격 증명을 읽는다.
- release에 signing 정보가 없으면 로컬/CI에서 명확히 실패하도록 guard를 둔다.
- 실제 배포용 keystore는 생성하거나 커밋하지 않고 runbook에 절차만 문서화한다.

### iOS release

- `Runner` target의 bundle identifier를 Android와 동일한 앱 식별자 계열로 맞춘다.
- `MARKETING_VERSION`, `CURRENT_PROJECT_VERSION`, `IPHONEOS_DEPLOYMENT_TARGET`을 릴리스 기준으로 통일한다.
- CI release lane은 unsigned archive만 생성하고, 실제 signing/export는 수동 또는 비밀값 주입 단계로 분리한다.

### CI/CD

- PR 게이트는 기존 분석/테스트 외에 Android debug APK smoke build와 unsigned iOS simulator build를 추가한다.
- tag `v*` workflow는 Android release APK와 unsigned iOS archive를 산출물로 업로드하고 GitHub release를 생성한다.

## Risks

- Android release signing 값이 누락되면 로컬 릴리스 빌드와 CI 릴리스 job이 즉시 실패해야 한다.
- iOS deployment target 상향은 오래된 시뮬레이터/기기 지원 범위를 줄이므로 문서와 설정이 함께 맞아야 한다.
- release shrinker 규칙이 부족하면 빌드는 통과해도 MediaPipe/TFLite 런타임 로딩이 실패할 수 있다.

## Validation

- `cd mobile && flutter pub get`
- `cd mobile && flutter analyze`
- `cd mobile && flutter test`
- `python3 -m pytest backend/tests -q`
- `python3 -m ruff check backend/app backend/tests`
- `python3 -m mypy backend/app`
- `./scripts/export-openapi.sh`
- `./scripts/validate-docs.sh`
