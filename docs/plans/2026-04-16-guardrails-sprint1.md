# 2026-04-16 Guardrails + Sprint 1 Plan

## Scope

- Self-review에서 확인된 9개 이슈에 대한 자동/수동 가드레일을 저장소에 반영한다.
- 가드레일 검증이 통과한 뒤 Sprint 1 목표인 네이티브 온디바이스 경로 검증 보강과 런타임 상태 UI를 구현한다.
- 기존 API 계약과 현재 한국어 UX는 유지한다.

## Phase 1. Guardrails

- `.pre-commit-config.yaml`를 실제 검증 흐름과 맞춘다.
- `docs-guard.yml`에 문서/계약 변경 알림, OpenAPI 드리프트 검사, 시드 source 일관성 검사를 추가한다.
- 네이티브 의존성 버전 고정 및 Android release debug signing 감지 스크립트를 추가한다.
- 수동 체크리스트와 런북을 문서화한다.

## Phase 2. Sprint 1 Harness

- Android/iOS 네이티브 브릿지 초기화 실패와 타임아웃 처리를 강화한다.
- 런타임 상태를 구조화해 Dart 레이어와 UI에서 상세히 노출한다.
- 홈 화면에 현재 런타임 상태, 폴백 여부, 개발자 패널을 추가한다.
- 위젯 테스트를 보강해 새 상태 UI를 검증한다.

## Validation Gates

가드레일 단계 완료 후:

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `python3 -m pytest backend/tests`
- `python3 -m ruff check backend/app backend/tests`
- `python3 -m mypy backend/app`
- `./scripts/export-openapi.sh`
- `./scripts/validate-docs.sh`
- 가드레일 스크립트 직접 실행

Sprint 1 완료 후:

- 위 검증 전체 재실행
- `.pre-commit-config.yaml` 훅 수동 실행 검증
- 필요 시 iOS 전용 검증은 macOS 가능한 범위에서 스크립트 수준으로 확인

## Notes

- 이 저장소는 이미 더티 워크트리일 수 있으므로 기존 미추적 리뷰/계획 문서는 건드리지 않는다.
- 실제 LiteRT 모델 아티팩트는 저장소 밖에 있으므로, 네이티브 성공 경로는 상태/오류 표면화와 빌드 가능한 하네스 강화에 집중한다.

## Progress

- Phase 1 완료:
  - pre-commit 훅, `docs-guard.yml`, OpenAPI/source/native guard 스크립트, 수동 가이드 문서를 추가했다.
  - Android/iOS 네이티브 의존성을 `0.10.21`로 고정하고, Android release debug signing 설정을 제거했다.
- Phase 2 완료:
  - 네이티브 브릿지 상태 보고를 상세화하고 초기화 타임아웃을 추가했다.
  - 홈 화면에 런타임 상태 카드, 결과별 응답 경로 표시, 개발자 정보 패널을 추가했다.
  - 위젯 테스트를 확장해 런타임 상태 UI를 검증했다.

## Validation Result

- `flutter pub get`
- `flutter analyze`
- `flutter test`
- `python3 -m pytest backend/tests`
- `python3 -m ruff check backend/app backend/tests`
- `python3 -m mypy backend/app`
- `./scripts/check-openapi-drift.sh`
- `./scripts/check_seed_source_consistency.py`
- `./scripts/check-native-dependency-pins.sh --strict`
- `./scripts/check-release-signing.sh`
- `./scripts/validate-docs.sh`
- `pre-commit run --all-files`
