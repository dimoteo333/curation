# 2026-04-16 마일스톤 리뷰

## 전체 진행 요약

현재 저장소는 더 이상 "문서만 있는 스캐폴드" 상태가 아니다. Flutter 모바일 앱과 FastAPI 백엔드의 첫 수직 슬라이스가 실제 코드와 테스트로 존재하며, 모바일 기본 런타임도 `CURATION_MODE=on_device` 기준으로 온디바이스 경로를 타도록 전환되어 있다.

다만 온디바이스 LLM 통합의 실질 상태는 "네이티브 브릿지 골격 + Dart 오케스트레이션 + 결정적 폴백"에 가깝다. Android Kotlin, iOS Swift 브릿지 핸들러와 의존성 선언은 존재하지만, 저장소에는 실제 LiteRT/Gemma 모델이 없고 테스트도 네이티브 추론 경로를 검증하지 않는다. 따라서 현재 사용자 경험은 로컬 벡터 검색은 실제로 수행하지만, 생성과 임베딩 품질은 환경에 따라 폴백 구현에 크게 의존한다.

## Phase별 완료 상태 및 상세 리뷰

### 초기 구현 계획 기준

| Phase | 상태 | 리뷰 |
| --- | --- | --- |
| Phase 1. Repository understanding and harness alignment | 완료 | 아키텍처 문서, 계약 문서, 스크립트, 워크플로가 모두 존재하고 구현 방향도 대체로 문서화되어 있다. 초기 플랜의 진행 로그는 실제 저장소 상태와 대체로 부합한다. |
| Phase 2. Development harness | 완료 | `backend/`와 `mobile/` 프로젝트가 모두 존재하며, 기본 테스트/분석/스크립트도 연결되어 있다. `Makefile`, `scripts/export-openapi.sh`, `scripts/validate-docs.sh`도 실제 동작 가능한 형태다. |
| Phase 3. Vertical slice implementation | 완료 | 백엔드 `POST /api/v1/curation/query`와 모바일 질문-응답 UI가 구현되어 있다. 다만 모바일의 기본 경로는 더 이상 백엔드 호출이 아니라 온디바이스 경로이며, 원래 플랜의 "모바일이 백엔드를 호출한다" 설명은 현재 상태와 다르다. |
| Phase 4. Quality and legibility | 부분완료 | OpenAPI와 핵심 아키텍처 문서는 있다. 그러나 일부 문서는 최신 동작과 어긋나고, CI의 `docs-guard.yml`은 비어 있으며, 네이티브 빌드/실기기 검증 기록은 없다. |
| Phase 5. Optional long-run orchestration readiness | 미완료 | 별도 오케스트레이션 준비 산출물은 없다. 현재 저장소 관점에서는 큰 문제는 아니지만, 플랜에 적힌 readiness artifact는 아직 없다. |

### 온디바이스 LLM 통합 계획 기준

| Phase | 상태 | 리뷰 |
| --- | --- | --- |
| Phase A. Research and native bridge setup | 부분완료 | `MethodChannel` 인터페이스와 Android/iOS 브릿지 핸들러는 존재한다. 하지만 "컴파일 및 실제 호출 검증"까지 확인된 상태는 아니며, 모델 부재 시 폴백이 기본이다. |
| Phase B. On-device embeddings and vector store | 부분완료 | SQLite 기반 `VectorDb`, 시드 레코드 인덱싱, 검색 테스트는 존재한다. 그러나 실제 네이티브 임베딩 모델 통합은 미검증이며 현재 기본 품질은 `KeywordHashEmbeddingService` 폴백에 좌우된다. |
| Phase C. On-device LLM inference | 부분완료 | `LlmEngine`과 한국어 프롬프트 렌더링은 있다. 그러나 실제 Gemma/LiteRT 추론 성공 여부는 저장소 차원에서 입증되지 않았고, 현재 테스트는 템플릿 생성 폴백만 검증한다. |
| Phase D. RAG pipeline integration | 부분완료 | 질문 → 임베딩 → 검색 → 프롬프트 → 생성 흐름은 코드상 연결되어 있고 기본 런타임도 온디바이스다. 다만 "실제 모델을 사용한 온디바이스 성공"이 아니라 "폴백 가능한 로컬 RAG 경로"까지 완성된 상태다. |
| Phase E. Validation and optimization | 부분완료 | 기본 검증 체인은 구성되어 있다. 하지만 Android/iOS 네이티브 빌드, 실기기 성능, 메모리 프로파일링, 모델 로딩 시간 최적화는 아직 손대지 않았다. |

## 실제 구현 검증 요약

### 모바일

- `mobile/lib/src/providers.dart`에서 기본 저장소가 `CURATION_MODE=on_device`일 때 `OnDeviceCurationRepository`를 선택한다.
- `OnDeviceCurationRepository`는 SQLite `VectorDb`에 시드 데이터를 넣고, 질의 임베딩 후 상위 3건을 검색한다.
- `LlmEngine`은 네이티브 브릿지 준비가 되면 `generate`를 호출하지만, 준비되지 않으면 한국어 템플릿 기반 응답으로 폴백한다.
- `LiteRtTextEmbeddingService`도 네이티브 임베더가 준비되지 않으면 `KeywordHashEmbeddingService`로 폴백한다.
- 따라서 현재 모바일 기본 UX는 "완전한 Gemma 기반 온디바이스 추론"이 아니라 "로컬 검색 + 조건부 네이티브 연동 + 안정적 폴백"이다.

### 백엔드

- FastAPI 앱, `/health`, `/api/v1/curation/query` 엔드포인트, Pydantic 스키마, OpenAPI 산출물이 존재한다.
- 백엔드 서비스는 실제 LLM 호출 없이 시드 데이터와 규칙 기반 토큰/동의어 매칭으로 응답을 생성한다.
- 모바일 기본 경로가 온디바이스로 이동했기 때문에 백엔드는 현재 "개발/계약/데모 하네스" 역할에 가깝다.

### 온디바이스 LLM 브릿지 실제 동작 상태

- Android:
  - `LiteRtLlmBridgeHandler.kt`가 `prepare`, `status`, `embed`, `generate`를 처리한다.
  - `com.google.mediapipe:tasks-genai`와 `com.google.mediapipe:tasks-text` 의존성이 선언돼 있다.
  - 모델 경로가 존재하면 `LlmInference`와 `TextEmbedder`를 초기화하도록 작성되어 있다.
- iOS:
  - `LiteRtLlmBridgeHandler.swift`와 `AppDelegate.swift`에서 동일 채널을 연결한다.
  - `MediaPipeTasksGenAI`, `MediaPipeTasksGenAIC`, `MediaPipeTasksText` Pod가 선언돼 있다.
- 결론:
  - 네이티브 브릿지 코드는 "실제로 연결돼 있다"기보다 "연결을 시도할 수 있는 구현이 저장소에 존재한다"는 표현이 정확하다.
  - 저장소 내 테스트와 CI는 네이티브 추론 성공을 입증하지 못한다.
  - 현재 확실히 동작한다고 말할 수 있는 것은 Dart 폴백 경로다.

## 테스트 현황

### 자동화된 테스트 범위

- 백엔드
  - `backend/tests/test_api.py`
  - `backend/tests/test_curation_service.py`
- 모바일
  - `mobile/test/widget_test.dart`
  - `mobile/test/vector_db_test.dart`
  - `mobile/test/on_device_curation_repository_test.dart`
- 모바일 통합 테스트
  - `mobile/integration_test/app_test.dart`

### 커버리지 평가

- 상태: 부분완료
- 장점:
  - 백엔드 핵심 API와 서비스의 정상/빈 결과 경로가 최소한으로 검증된다.
  - 모바일은 위젯, 로컬 벡터 검색, 온디바이스 저장소 폴백 경로가 검증된다.
- 한계:
  - 코드 커버리지 리포트 자체가 없다.
  - 네이티브 Android/iOS 브릿지 성공 경로 테스트가 없다.
  - 원격 모드(`CURATION_MODE=remote`) UI/저장소 경로 테스트가 없다.
  - 실패 케이스, 경계값, OpenAPI 드리프트, 네트워크 오류, DB 재초기화, 마이그레이션 시나리오 테스트가 없다.
  - 통합 테스트는 기본 온디바이스 렌더링만 확인하며, 실제 백엔드 연결 여부나 네이티브 모델 사용 여부를 검증하지 않는다.

## 문서와 실제 코드의 불일치

1. `docs/plans/2026-04-16-initial-implementation-plan.md`
   모바일이 백엔드를 호출하는 수직 슬라이스 설명이 중심인데, 실제 기본 런타임은 온디바이스다.
2. `docs/runbooks/ios-simulator.md`
   현재 저장소 기본 경로는 온디바이스인데도 여전히 백엔드 기동을 표준 플로우로 안내한다.
3. `.github/workflows/ios-simulator.yml`
   iOS 통합 테스트 전에 백엔드를 띄우지만, 현재 `integration_test/app_test.dart`는 기본 설정상 백엔드를 요구하지 않는다.
4. `.github/workflows/docs-guard.yml`
   워크플로 파일이 존재하지만 비어 있어 실제 가드 역할을 하지 못한다.
5. 플랜 문서의 "full required validation passed" 기록
   저장소 내에서는 네이티브 온디바이스 경로와 Android/iOS 빌드 성공까지 입증되지 않았으므로, 표현상 과감한 부분이 있다.

## 발견된 이슈 및 기술 부채 목록

1. 네이티브 브릿지 미검증
   브릿지 구현은 있으나 실제 모델 로딩 및 추론 성공이 테스트/CI로 보장되지 않는다.
2. 폴백 품질 의존
   임베딩은 해시 기반, 생성은 템플릿 기반이다. 데모는 가능하지만 실제 개인 큐레이션 품질은 제한적이다.
3. 브루트포스 검색
   `VectorDb`는 모든 임베딩을 JSON으로 읽어와 Dart에서 코사인 유사도를 계산한다. 데이터가 커지면 성능이 급격히 나빠질 가능성이 높다.
4. 모델 및 네이티브 의존성 재현성 부족
   Android는 `latest.release`를 사용하고, iOS Pod 버전도 고정돼 있지 않다.
5. 프로덕션 빌드 준비 부족
   Android release 빌드는 여전히 debug signing config를 사용한다.
6. 저장 데이터 보호 부재
   SQLite 벡터 DB와 시드/향후 사용자 데이터는 암호화나 키 관리 없이 평문 저장 구조다.
7. 데이터 인제스트 부재
   캘린더/노트/일기 실제 연동이 없고, 현재는 하드코딩된 시드 데이터만 사용한다.
8. 관측성 부족
   크래시 리포팅, 성능 로그, 모델 로딩 telemetry, 사용자 피드백 수집 저장이 없다.
9. 백엔드와 모바일 시드 모델의 의미 차이
   모바일은 한국어 `source` 값을 쓰고, 백엔드는 영문 `source` 값을 사용한다. 도메인 일관성이 약하다.

## 알려진 버그 또는 잠재 결함

- 네이티브 모델 경로가 잘못되면 사용자는 조용히 폴백 응답을 보게 될 가능성이 높다. 현재 UI에서 "실제 Gemma 사용 중인지" 명확히 드러나지 않는다.
- 통합 테스트 이름과 런북은 여전히 백엔드 의존처럼 보이지만, 실제 검증 범위는 온디바이스 폴백 렌더링에 더 가깝다.
- `VectorDb`는 스키마 버전 1 고정이며 마이그레이션 전략이 없다.
- 네이티브 런타임 초기화 실패 메시지는 내부적으로 보존되지만, 사용자 친화적 설정 화면이나 복구 동선은 없다.

## 성능 / 보안 / 프라이버시 우려사항

### 성능

- 벡터 검색이 ANN 없이 전체 스캔이라 데이터 증가 시 병목이 예상된다.
- 임베딩과 생성 모두 준비 시점에 모델 초기화 비용이 크며, 현재 캐시/워밍 전략이 없다.
- 네이티브 추론 성공 경로의 메모리 사용량, 첫 토큰 지연, 배터리 영향이 전혀 측정되지 않았다.

### 보안

- 사용자 데이터 저장소 암호화가 없다.
- 모델 파일 무결성 확인이나 checksum 검증이 없다.
- 릴리스 서명/배포 설정이 미완성이다.
- 권한 연동, 인증, 결제 같은 민감 플로우는 아직 없지만, 향후 데이터 인제스트 단계에서 민감도가 급상승할 예정이다.

### 프라이버시

- 현재 기본 경로는 온디바이스라 방향성은 맞다.
- 그러나 실제 데이터 인제스트/권한 제어/UI 동의 흐름은 아직 구현되지 않았다.
- `CURATION_MODE=remote`가 존재하므로, 향후 실사용 빌드에서 원격 모드가 노출되지 않도록 배포 정책 분리가 필요하다.

## CI/CD 파이프라인 상태

- `pr-gate.yml`
  - 백엔드 Ruff/mypy/pytest
  - 모바일 `flutter pub get`, `flutter analyze`, `flutter test`
  - OpenAPI export 및 docs validation
- `ios-simulator.yml`
  - macOS 러너에서 Flutter 의존성 설치, 백엔드 기동, iOS integration test 수행
- 상태 평가: 부분완료
  - 장점: PR 단계의 기본 품질 게이트는 있다.
  - 한계: 릴리스 빌드, 서명, 배포, 크래시 리포팅, 스토어 업로드, 버전 태깅 자동화는 없다.
  - 한계: 네이티브 LLM 실제 성공 경로를 검증하는 job이 없다.
  - 한계: `docs-guard.yml`은 빈 파일이다.

## 현재 아키텍처 다이어그램

```text
[Flutter UI]
  HomeScreen
    -> CurationController
      -> RequestCurationUseCase
        -> CurationRepository
           -> default: OnDeviceCurationRepository
              -> VectorDb (SQLite)
              -> TextEmbeddingService
                 -> native bridge if model ready
                 -> else KeywordHashEmbeddingService
              -> LlmEngine
                 -> native bridge if model ready
                 -> else Korean template fallback
           -> optional: CurationRepositoryImpl
              -> ApiClient
              -> FastAPI /api/v1/curation/query

[FastAPI Backend]
  Router
    -> CurationService
      -> SeedRecordRepository
        -> seeded records only

[Native Runtime Layer]
  Flutter MethodChannel
    -> Android Kotlin bridge
       -> MediaPipe Tasks GenAI / Text
    -> iOS Swift bridge
       -> MediaPipeTasksGenAI / Text
```

## 보안 / 프라이버시 체크리스트 상태

| 항목 | 상태 | 메모 |
| --- | --- | --- |
| 기본 질문 처리 온디바이스 경로 | 완료 | 기본 런타임이 `on_device`다. |
| 원격 API 계약 분리 유지 | 완료 | 백엔드는 하네스/계약 검증 경로로 남아 있다. |
| 사용자 개인 데이터 외부 전송 차단 보장 | 부분완료 | 기본 경로는 온디바이스지만 실제 인제스트/배포 정책까지는 없다. |
| 로컬 저장 데이터 암호화 | 미완료 | SQLite DB 보호 계층이 없다. |
| 모델 파일 무결성 검증 | 미완료 | checksum 또는 서명 검증이 없다. |
| 권한 요청/동의 UX | 미완료 | 캘린더/메모/파일 연동 자체가 아직 없다. |
| 원격 모드 실사용 차단 정책 | 미완료 | 개발용 플래그는 있으나 배포 분리 정책 문서가 없다. |
| 진단/의료 오용 방지 프롬프트 | 부분완료 | 프롬프트 가드는 있으나 실제 Gemma 경로에서 검증되지 않았다. |

## 다음 단계 후보 평가

| 후보 | 예상 복잡도 | 선행 의존성 | 사용자 가치 | 권장 순서 | 이유 |
| --- | --- | --- | --- | --- | --- |
| 실제 LiteRT-LM/Gemma 네이티브 브릿지 완성 | 높음 / 3~5일+ | 모델 선정, Android/iOS 빌드 검증, 모델 배포 방식 결정 | 높음 | 1 | 현재 가장 큰 불확실성이다. 폴백 중심 상태를 실제 제품 코어로 바꾸려면 우선 해결해야 한다. |
| 임베딩 모델 통합 | 중간~높음 / 2~4일 | 네이티브 텍스트 임베더 자산 확정, 벡터 차원/저장 형식 고정 | 높음 | 2 | 검색 품질이 전체 제품 경험을 좌우한다. 현재 해시 임베딩은 임시 구현에 가깝다. |
| 데이터 인제스트 파이프라인 | 높음 / 3~6일+ | 권한 UX, 데이터 모델 확장, 중복 제거 정책 | 높음 | 4 | 실제 사용자 가치는 크지만, 검색/생성 코어가 불안정한 상태에서 먼저 확장하면 기술 부채가 커진다. |
| UI/UX 개선 | 중간 / 1~3일 | 런타임 상태 노출 설계 | 중간~높음 | 3 | 네이티브 준비 상태, 폴백 여부, 모델 설정 실패를 사용자에게 보여줘야 디버깅과 신뢰가 가능하다. |
| 성능 최적화 | 중간~높음 / 2~4일 | 실제 모델 연동, 프로파일링 지표 확보 | 중간 | 5 | 현재는 측정 대상이 되는 실제 추론 경로가 먼저 안정화돼야 한다. |
| 프로덕션 준비 | 높음 / 3~5일+ | 기능 안정화, 서명/배포 정책, 크래시 리포팅 선정 | 중간 | 6 | 아직 코어 제품 가설이 완성되지 않아 지금 투자 효율이 낮다. |
| 검색 히스토리 / 즐겨찾기 / 통계 대시보드 | 낮음~중간 / 1~3일 | 핵심 질의 품질 확보 | 낮음~중간 | 7 | 기반 검색/생성 품질이 먼저다. 현재 단계에서 우선순위가 낮다. |

## 권장 다음 3개 스프린트

### 스프린트 1 (1~2일)

- 목표: 네이티브 온디바이스 경로를 "정말로 동작하는 상태"로 끌어올리기
- 작업:
  - Android Kotlin / iOS Swift 브릿지 실기기 또는 시뮬레이터 빌드 검증
  - 모델 경로/포맷/초기화 실패 케이스 정리
  - 앱 UI에 런타임 상태 표시 추가
  - 폴백 사용 여부를 명확히 보여주는 디버그 정보 추가

### 스프린트 2 (1~2일)

- 목표: 검색 품질을 임시 해시 임베딩에서 실제 임베딩 모델 기반으로 전환
- 작업:
  - MediaPipe Text Embedder 실제 모델 통합
  - 벡터 차원/저장 형식 고정
  - 검색 품질 회귀 테스트 추가
  - 시드 데이터 외 샘플 데이터셋으로 retrieval 평가

### 스프린트 3 (1~2일)

- 목표: 실제 사용자 흐름에 가까운 최소 입력 파이프라인과 설정 UX 확보
- 작업:
  - 파일 기반 메모/일기 import 최소 1종 추가
  - 설정 화면에서 모델 경로/데이터 소스/개인정보 옵션 노출
  - 폴백/네이티브 상태에 따른 UX 분기 정리
  - 향후 캘린더/메모 연동을 위한 데이터 모델 정제

## 권장 순서에 대한 판단

현재 가장 중요한 것은 "모바일이 온디바이스라고 주장하는데 실제로는 무엇이 돌고 있는가"를 불확실하지 않게 만드는 일이다. 따라서 첫 우선순위는 네이티브 브릿지 완성과 임베딩 모델 통합이다. 데이터 인제스트나 대시보드 같은 기능 확장은 그 이후가 맞다. 지금은 코어 검색/생성 품질과 런타임 신뢰성을 먼저 확보해야 한다.

## 검증 상태

- 문서 작성 후 검증을 재실행했다.
- 이 머신에는 `python` 바이너리가 없어 백엔드 명령은 동일 의미의 `python3 -m ...`으로 실행했다.
- 결과적으로 모바일/백엔드/문서/계약 검증은 모두 통과했다.

### 명령 실행 결과

- `cd mobile && flutter pub get`: 통과
- `cd mobile && flutter analyze`: 통과
- `cd mobile && flutter test`: 통과
- `python3 -m pytest backend/tests -q`: 통과 (`4 passed`)
- `python3 -m ruff check backend/app backend/tests`: 통과
- `python3 -m mypy backend/app`: 통과
- `bash scripts/export-openapi.sh`: 통과
- `bash scripts/validate-docs.sh`: 통과
