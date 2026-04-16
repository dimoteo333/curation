# 2026-04-17 Sprint 3 Plan

## Scope

- 모바일 온디바이스 경로에 실제 파일 기반 메모/일기 import 파이프라인을 추가한다.
- 설정 화면과 최소 온보딩을 도입해 런타임 전환, 로컬 데이터 상태, 프라이버시 안내를 사용자에게 노출한다.
- `LifeRecord`와 `VectorDb`를 v2로 확장해 향후 캘린더/메모/일기 연동을 수용하되, 기존 시드 데이터와 현재 질의 UX는 유지한다.
- 백엔드 OpenAPI 계약은 변경하지 않는다.

## Goals

- `.txt`, `.md` 파일을 읽어 `LifeRecord`로 변환하고 로컬 벡터 DB에 임베딩과 함께 저장한다.
- 홈 화면에서 설정 화면으로 이동할 수 있어야 한다.
- 첫 실행 시 온보딩을 노출하고, 이후에는 SharedPreferences에 저장된 상태로 재노출을 막는다.
- 데이터 저장 위치와 원격 전송 정책을 한국어로 명확히 안내한다.

## Design

### Data model v2

- `LifeRecord`에 `importSource`와 `metadata`를 추가한다.
- 기존 `source` 필드는 한국어 표시값으로 유지해 현재 UI와 백엔드 시드 source consistency 규칙을 깨지 않는다.
- `VectorDb` 스키마를 v2로 올리고 다음 컬럼을 추가한다.
  - `import_source TEXT NOT NULL`
  - `metadata_json TEXT NOT NULL`
- v1 -> v2 마이그레이션 시 기존 `source` 값을 기반으로 `import_source`를 채운다.
  - `일기 -> diary`
  - `캘린더 -> calendar`
  - `메모 -> note`

### Record bootstrap and privacy

- 시드 데이터는 첫 초기화에만 주입한다.
- 이후 사용자가 데이터를 비워도 자동으로 다시 시드되지 않도록 로컬 bootstrap 상태를 SharedPreferences에 저장한다.
- 설정 화면에는 두 종류의 관리 액션을 둔다.
  - 기본 시드로 초기화
  - 전체 데이터 삭제

### File import

- `mobile/lib/src/data/import/` 아래에 파일 피커, 파서, import 서비스 코드를 둔다.
- Markdown은 첫 헤더를 제목으로, 나머지를 본문으로 쓴다.
- 일반 텍스트는 첫 줄을 제목 후보로 사용하고, 조건이 맞지 않으면 파일명을 제목으로 사용한다.
- `createdAt`은 파일 수정 시각을 사용한다.
- `metadata`에는 파일명, 확장자, 수정 시각, import 시각 정도만 저장하고 절대 경로는 저장하지 않는다.

### Settings and onboarding

- 설정은 SharedPreferences 기반으로 저장한다.
- 런타임 모드와 개발자용 모델 경로는 환경변수 기본값 위에 로컬 override를 두는 방식으로 구현한다.
- 프라이버시 문구는 온디바이스 모드 기준 보장을 설명하되, 원격 모드는 개발자 테스트 전용임을 함께 명시한다.

## Risks

- `VectorDb` 마이그레이션은 기존 로컬 DB가 있는 환경에서 한 번 실행되므로, 컬럼 기본값과 하위 호환 매핑을 명확히 유지해야 한다.
- 파일 import가 빈 파일 또는 헤더만 있는 Markdown을 만날 수 있으므로, 파싱 실패와 스킵 집계를 UI에 드러내야 한다.
- 원격 모드 토글을 넣더라도 기존 API 계약은 유지해야 하며, 기본 UX는 여전히 온디바이스 경로를 중심으로 설명해야 한다.

## Validation

- `cd mobile && flutter pub get`
- `cd mobile && flutter analyze`
- `cd mobile && flutter test`
- `python3 -m pytest backend/tests -q`
- `python3 -m ruff check backend/app backend/tests`
- `bash scripts/validate-docs.sh`

## Progress

- `LifeRecord` v2와 `VectorDb` schema v2 마이그레이션을 구현했다.
- SharedPreferences 기반 온보딩/설정 상태를 추가했다.
- 설정 화면과 홈 화면 설정 진입 버튼을 구현했다.
- `.txt`/`.md` 파일 import 서비스와 로컬 저장 경로를 구현했다.
- import, 설정, 온보딩, 마이그레이션 테스트를 추가했다.

## Validation Result

- `cd mobile && flutter pub get`
- `cd mobile && flutter analyze`
- `cd mobile && flutter test`
- `python3 -m pytest backend/tests -q`
- `python3 -m ruff check backend/app backend/tests`
- `bash scripts/validate-docs.sh`
