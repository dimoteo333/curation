# 2026-04-17 Sprint 9 Plan

## Scope

- 모바일 온디바이스 경로에 기기 캘린더 읽기 import를 추가한다.
- Apple Notes 직접 연동이 불가능한 iOS 제약을 문서 기반 fallback으로 안내한다.
- 로컬 import deduplication과 import history를 추가해 반복 인제스트 비용과 중복 저장을 줄인다.
- 설정 화면에 캘린더 동기화 상태, import 이력, 데이터 소스 요약을 노출한다.
- 백엔드 HTTP 계약은 변경하지 않는다.

## Goals

- 최근 30일 기기 캘린더 이벤트를 `LifeRecord`로 변환해 로컬 벡터 DB에 저장한다.
- 캘린더 권한 상태, 마지막 동기화 시각, 누적 가져온 일정 수를 설정에서 보여 준다.
- 파일/캘린더 import 이력을 로컬에 저장하고 중복 import를 막는다.
- Apple Notes는 직접 읽지 않고 `.txt` export + 파일 가져오기 경로를 한국어 가이드로 안내한다.

## Design

### Data model and migration

- `LifeRecord`에 `sourceId`를 추가해 import 원본의 안정적인 식별자를 분리한다.
- `VectorDb` 스키마를 v5로 올리고 `documents.source_id` 컬럼과 `(import_source, source_id)` unique index를 추가한다.
- 기존 레코드는 마이그레이션 시 `source_id = id`로 채워 하위 호환을 유지한다.
- 레코드 저장은 primary key `id`와 별도로 composite unique key 기준 `REPLACE` upsert를 사용한다.

### Import history

- `SharedPreferences`에 최근 import 항목과 source별 dedupe 집합을 JSON으로 저장한다.
- 파일은 `path + modifiedAt` 기준으로 동일 import를 건너뛴다.
- 캘린더는 `eventId` 기준으로 unique count를 유지하되, 동기화 시에는 기존 레코드를 upsert해 변경 내용을 반영한다.

### Calendar import

- maintained plugin으로 `device_calendar_plus`를 사용한다.
- 권한 허용 후 현재 시점 기준 최근 30일 범위를 조회한다.
- 이벤트 제목/설명/시간/위치/캘린더 메타데이터를 `LifeRecord`로 변환한다.
- 제목과 카테고리/캘린더 이름에서 태그를 추출한다.

### Notes fallback

- Apple Notes를 직접 읽는 Flutter plugin을 전제로 두지 않는다.
- iOS 사용자는 Notes에서 텍스트를 내보낸 뒤 기존 파일 import로 가져오도록 안내한다.
- 설정 화면에는 별도 "노트 가져오기" 섹션과 단계별 가이드를 노출한다.

## Risks

- SQLite 스키마 업그레이드는 기존 암호화 저장 포맷과 함께 동작해야 하므로 migration test가 필요하다.
- 캘린더 이벤트는 플랫폼별 필드 가용성이 다를 수 있으므로 제목/시간이 비어 있는 경우 fallback 문구를 유지해야 한다.
- 캘린더 권한을 꺼도 기존에 가져온 일정은 로컬 DB에 남으므로 UI 문구로 범위를 명확히 안내해야 한다.

## Validation

- `cd mobile && flutter pub get`
- `cd mobile && flutter analyze`
- `cd mobile && flutter test`
- `python3 -m pytest backend/tests -q`
- `python3 -m ruff check backend/app backend/tests`
- `python3 -m mypy backend/app`
- `./scripts/export-openapi.sh`
- `./scripts/validate-docs.sh`
