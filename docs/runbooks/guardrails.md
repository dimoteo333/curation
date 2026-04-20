# Guardrails Runbook

## 목적

Self-review에서 확인된 9개 이슈를 자동/수동 가드레일로 묶어, 문서와 코드가 같이 진화하고 폴백 의존 상태를 숨기지 않도록 한다.

## 이슈별 가드레일 현황

| 이슈 | 자동 가드레일 | 수동 가드레일 | 우회 방지 전략 |
| --- | --- | --- | --- |
| 1. 네이티브 브릿지 미검증 | `flutter test`, 런타임 상태 UI 테스트, release signing/native dependency 검사 | 네이티브 브릿지 변경 검증 절차 | 브릿지 변경 시 Kotlin/Swift/Dart 3면 검증을 문서화하고, 홈 화면에서 실제 상태를 노출한다. |
| 2. 폴백 품질 의존 | 런타임 상태 배지, 위젯 테스트, 폴백 메시지 검증 | 폴백 vs 네이티브 경로 테스트 가이드 | 폴백을 조용히 숨기지 않고 UI/개발자 패널에서 드러낸다. |
| 3. 브루트포스 검색 | 문서화된 성능 위험 신호와 개발자 패널 노출 가이드 | 검색 성능 예산 점검 절차 | 레코드 수 임계치와 질의 시간 예산을 명시하고 초과 시 ANN 전환을 요구한다. |
| 4. 모델/네이티브 의존성 재현성 부족 | `check-native-dependency-pins.sh` | 버전 업그레이드 시 근거 문서화 | 동적 버전 사용을 CI/pre-commit에서 차단한다. |
| 5. 프로덕션 빌드 준비 부족 | `check-release-signing.sh` | 릴리스 전 서명/배포 체크리스트 | release debug signing을 하드 실패로 막는다. |
| 6. 저장 데이터 보호 | 암호화 테스트, 문서 검증, delete-all 동작 확인 | 키 관리와 마이그레이션 점검 | 개인 텍스트 필드는 암호화 저장을 유지하고, 키 저장소/삭제 경로가 우회되지 않도록 확인한다. |
| 7. 데이터 인제스트 부재 | 없음 | 데이터 모델/마이그레이션 체크리스트 | 실제 인제스트를 추가할 때 권한, 저장, 중복 제거를 함께 검토하게 만든다. |
| 8. 관측성 부족 | 런타임 상세 상태, 초기화 메시지, 에러 상태 노출 | 운영 telemetry 추가 전 체크리스트 | 최소한 개발자 패널에서 현재 실패 원인을 보여 주고, 숨은 실패를 줄인다. |
| 9. 모바일/백엔드 source 의미 차이 | `check_seed_source_consistency.py` | source vocabulary 변경 절차 | ID와 source mapping을 자동 검증해 의미 드리프트를 조기에 잡는다. |

## 자동 감지 방법

- pre-commit:
  - 모바일 `flutter pub get`, `flutter analyze`, `flutter test`
  - 백엔드 `ruff`, `mypy`, `pytest`
  - `check-openapi-drift.sh`
  - `check_seed_source_consistency.py`
  - `check-native-dependency-pins.sh --strict`
  - `check-release-signing.sh`
  - `validate-docs.sh`
- GitHub Actions `docs-guard.yml`:
  - 문서/계약/아키텍처 파일 변경 시 PR 코멘트로 리뷰 알림
  - `backend/openapi.json` 드리프트 검출
  - mobile/backend 시드 source 일관성 검증
  - 네이티브 의존성 버전 고정, release signing 가드 재실행

## 수동 감지 방법

- `docs/contributing.md` 체크리스트로 변경 전후 검토
- 홈 화면 런타임 배지와 개발자 패널에서 실제 상태 확인
- 모델 경로 미설정, 잘못된 경로, 실제 모델 연결 3가지 케이스 수동 실행
- 스키마 변경 시 `VectorDb` 버전과 재색인/마이그레이션 문서 확인
- Android 변경 시 `mobile/android/app/build.gradle.kts`에서 `minSdk >= 24`, `namespace`, `applicationId`, 고정 버전 의존성, release ProGuard 설정을 함께 확인
- Android 변경 시 `mobile/android/app/src/main/AndroidManifest.xml`에서 `INTERNET`, import 경로 관련 읽기 권한, LiteRT-LM GPU용 native-library 선언을 함께 확인
- Android 변경 시 `flutter build apk --debug` 또는 `./gradlew :app:assembleDebug`로 실제 컴파일 스모크 테스트를 남긴다

## 우회 방지 전략

- 문서만 바꾸고 코드가 바뀌지 않는 PR도 `docs-guard.yml`이 PR 코멘트를 남기게 한다.
- `backend/openapi.json`은 export 후 `git diff --exit-code`로 강제 동기화한다.
- 네이티브 버전은 동적 버전 문자열을 금지해 "나중에 최신으로 풀리겠지" 식 우회를 막는다.
- release signing은 warning이 아니라 error로 처리해 배포 전에 걸리도록 한다.
- 폴백은 숨기지 않고 한국어 UI에서 명시해 "네이티브가 되는 줄 알았는데 사실은 폴백" 상태를 줄인다.
- Android는 release shrinker를 끄는 식으로 문제를 숨기지 않고, 필요한 keep 규칙을 명시적으로 추가해 release 빌드에서도 같은 브릿지 계약을 유지한다.

## 창의적 해결책

### SQLite 암호화 운영 전략

1. 현재 구현은 앱 계층 암호화로 `title`, `content`, `tags_json`, `metadata_json`을 보호하고, 키는 Keychain/Keystore 기반 secure storage에 둔다.
2. 스키마 변경 시 기존 평문 또는 구버전 암호문이 남지 않도록 마이그레이션 테스트를 추가한다.
3. delete-all 흐름은 행 삭제가 아니라 SQLite 파일과 sidecar 파일 제거를 우선으로 유지한다.
4. 원격 백업/복구 정책이 생기면 키 회전, 복구 불가 UX, 다중 기기 정책을 별도 설계한다.

### 브루트포스 검색 성능 저하 사전 감지

- `VectorDb`가 brute-force 모드일 때 레코드 수와 최근 질의 시간을 개발자 패널에 표시한다.
- 반복 질문은 정규화 캐시와 검색 결과 캐시를 사용해 불필요한 전체 스캔을 줄인다.
- 기준 예시:
  - 1,000건 초과 또는 p95 검색 시간이 120ms 초과면 경고
  - 5,000건 초과면 ANN/인덱스 전략 전환을 필수 항목으로 승격
- CI에서는 안정적인 성능 수치 대신 알고리즘 모드와 임계치 노출 여부를 검증하고, 실제 성능은 기기 벤치마크 잡으로 분리한다.

### 네이티브 모델 로딩 실패 UX 보호 장치

- 초기화 타임아웃 시 무한 스피너 대신 즉시 폴백으로 전환하고 이유를 한 줄로 노출한다.
- 모델 경로 오류와 초기화 실패를 구분해 보여 준다.
- 질문 제출은 막지 않되, "현재는 템플릿 폴백"을 배지로 명시한다.

### 폴백 상태 UI 가이드라인

- 홈 화면 상단에 현재 경로를 한국어 배지로 노출한다.
- 생성과 임베딩 상태를 분리해 `LLM: 네이티브/폴백`, `임베딩: 네이티브/의미 폴백`으로 함께 보여 준다.
- 결과 카드에는 직전 응답이 네이티브인지 폴백인지 다시 한 번 표시한다.
- 개발자 패널에는 플랫폼, 모델 경로 구성 여부, 파일 존재 여부, 마지막 오류, 초기화 시간만 노출하고 민감한 절대 경로는 노출하지 않는다.

### CI에서 네이티브 빌드 성공 여부를 검증하는 방법

- Android:
  - `flutter build apk --debug` 또는 `./gradlew :app:assembleDebug`로 최소 컴파일 스모크 테스트를 추가한다.
  - release 검증 시 shrinker/R8 활성화 상태와 `proguard-rules.pro`의 LiteRT-LM/TFLite keep 규칙을 함께 확인한다.
  - 현재는 `embed`가 네이티브 미지원이어야 하므로, 상태 응답이 `native-partial` 또는 폴백으로 내려오고 Dart 의미 임베딩으로 계속 동작하는지 확인한다.
- iOS:
  - macOS 러너에서 `flutter build ios --simulator --no-codesign` 또는 `xcodebuild -workspace Runner.xcworkspace -scheme Runner -sdk iphonesimulator build`를 사용한다.
- 운영 원칙:
  - 모델 아티팩트 없이도 "브릿지 코드가 컴파일 가능한가"를 먼저 검증한다.
  - 실제 모델 로딩 성공은 별도 실기기/nightly lane으로 분리해 첫 토큰 시간, 메모리, 실패 로그를 수집한다.
