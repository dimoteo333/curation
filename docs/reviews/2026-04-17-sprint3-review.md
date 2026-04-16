# 2026-04-17 Sprint 3 Review

## Summary

Sprint 3 목표였던 최소 데이터 파이프라인과 설정 UX를 모바일 온디바이스 경로에 추가했다. 이제 앱은 첫 실행 시 온보딩을 보여 주고, 설정 화면에서 런타임 모드와 모델 경로를 관리하며, `.txt`/`.md` 파일을 로컬 벡터 DB로 가져올 수 있다.

## Completed

- `LifeRecord`를 v2로 확장해 `importSource`와 `metadata`를 추가했다.
- `VectorDb`를 schema v2로 올리고 v1 -> v2 마이그레이션을 구현했다.
- SharedPreferences 기반 앱 설정 상태를 도입해 다음 항목을 로컬에 저장한다.
  - 첫 실행 온보딩 완료 여부
  - 런타임 모드
  - LLM/임베딩 모델 경로
- 설정 화면을 추가했다.
  - 온디바이스/원격 모드 전환
  - 현재 런타임 상태 표시
  - 저장된 기록 수와 벡터 DB 크기 표시
  - 파일 import
  - 기본 시드 복원 / 전체 데이터 삭제
  - 프라이버시 안내
  - 앱 버전과 라이선스
- 홈 화면에 설정 진입 버튼을 추가했다.
- 파일 import 서비스를 추가했다.
  - `.md`는 첫 헤더를 제목으로 사용
  - `.txt`는 첫 줄을 제목 후보로 사용
  - 파일 수정 시각을 `createdAt`으로 사용
  - 임베딩 포함 로컬 Vector DB 저장

## Validation

- `cd mobile && flutter analyze`
- `cd mobile && flutter test`

## Residual Risks

- 파일 import는 현재 텍스트와 Markdown만 다루며, 캘린더/메모 앱 연동 권한 UX는 후속 스프린트 범위다.
- 로컬 DB는 여전히 평문 저장이며, 암호화는 별도 설계가 필요하다.
- 설정 화면의 원격 모드는 개발자 하네스용이므로 배포 빌드 노출 정책은 계속 주의가 필요하다.
