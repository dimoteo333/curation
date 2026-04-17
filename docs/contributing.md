# Contributing Guide

## 체크리스트

- 모바일/백엔드/계약/문서 중 변경 범위를 먼저 적고, 교차 레이어 변경이면 `docs/plans/<date>-<task>.md`를 먼저 만든다.
- API 응답 shape를 건드렸다면 `backend/openapi.json`, `docs/architecture/contracts.md`, 모바일 DTO와 테스트를 같은 변경에 포함한다.
- 모바일 온디바이스 경로를 건드렸다면 폴백 경로와 네이티브 경로를 모두 확인한다.
- 시드 데이터나 도메인 source 값을 건드렸다면 모바일/백엔드 양쪽 파일과 일관성 검사 스크립트를 통과시킨다.
- 문서와 코드가 어긋나지 않도록 `docs/architecture/*.md`, `docs/runbooks/guardrails.md`, `AGENTS.md`를 필요한 범위에서 함께 갱신한다.
- 변경 후 필수 검증을 모두 실행하고, 실패가 남아 있으면 다음 단계로 넘어가지 않는다.

## 네이티브 브릿지 변경 검증 절차

- `MethodChannel` 이름, 메서드 이름, 인자 키는 Android Kotlin, iOS Swift, Dart 세 레이어에서 동일해야 한다.
- 모델 경로가 비어 있는 경우, 존재하지 않는 경우, 파일은 있지만 초기화에 실패하는 경우를 각각 확인한다.
- 브릿지 초기화 타임아웃이 발생했을 때 UI가 무한 로딩 대신 폴백 상태와 복구 힌트를 보여주는지 확인한다.
- Android 변경 시 `mobile/android/app/build.gradle.kts`의 의존성 버전 고정과 release signing guard를 확인한다.
- iOS 변경 시 `mobile/ios/Podfile`의 버전 고정과 `pod install` 가능 여부를 확인한다.
- 최소 1회는 `flutter test`로 브릿지 미연결 테스트 환경이 계속 통과하는지 확인한다.

## 폴백 vs 네이티브 경로 테스트 가이드

- 폴백 확인:
  `flutter test` 환경에서는 `MissingPluginException` 기반 폴백이 정상 동작해야 한다.
- 모델 경로 누락 확인:
  `--dart-define=LLM_MODEL_PATH=` 와 `--dart-define=EMBEDDER_MODEL_PATH=` 상태에서 홈 화면 런타임 배지가 생성 폴백과 의미 임베딩 폴백 상태를 함께 표시해야 한다.
- 잘못된 경로 확인:
  존재하지 않는 절대 경로를 넘겨 초기화 실패 메시지와 개발자 패널 상세 정보 노출을 확인한다.
- 네이티브 확인:
  실제 모델 파일을 연결한 뒤 홈 화면이 `네이티브 LLM 사용 가능` 또는 `LLM: 네이티브`, `임베딩: 네이티브` 상태를 표시하고, 생성 결과가 폴백 문구 없이 반환되는지 본다.
- 회귀 확인:
  네이티브 실패 시에도 질문 제출, 의미 임베딩 검색 결과, 후속 질문 UX가 유지되어야 한다.

## 데이터 모델 변경 체크리스트

- SQLite 스키마 버전 증가 여부와 하위 호환 마이그레이션이 필요한지 먼저 판단한다.
- 마이그레이션이 필요하면 손실 가능성, 재색인 비용, 롤백 가능성을 `docs/plans/`에 적는다.
- 새 필드를 추가하면 시드 데이터, DTO, 도메인 엔티티, 테스트 픽스처를 함께 갱신한다.
- record ID, source, timestamp 형식 변경 시 mobile/backend seed consistency 검사를 돌린다.
- 저장 형식이 바뀌면 기존 DB가 있는 환경에서 재초기화 또는 점진 마이그레이션 전략을 문서화한다.

## 보안 및 프라이버시 필수 확인사항

- 개인 데이터는 기본적으로 온디바이스에 남아야 하며, 원격 전송이 생기면 명시적 동의와 배포 정책 분리가 필요하다.
- 모델 파일과 로컬 DB는 평문 저장을 기본값으로 두지 않는다. 민감 데이터 암호화와 키 관리 변경 시 마이그레이션, 삭제, 테스트 경로를 함께 기록한다.
- 로그에는 질문 원문, 개인 기록 전문, 절대 모델 경로 같은 민감 정보가 남지 않도록 한다.
- release build 설정은 debug signing, 개발용 원격 모드, 테스트 전용 패널 노출이 없는지 확인한다.
- 인증, 결제, 권한, 보안 민감 흐름을 건드리면 `AGENTS.md` 기준으로 사람 리뷰로 에스컬레이션한다.

## 권장 명령

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
