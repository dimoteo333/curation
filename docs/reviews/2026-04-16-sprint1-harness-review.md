# 2026-04-16 Sprint 1 Harness Review

## 요약

Sprint 1 목표였던 네이티브 온디바이스 경로 검증 보강과 런타임 상태 UI 추가를 완료했다. 현재 홈 화면은 네이티브 준비 상태, 템플릿 폴백 여부, 마지막 응답 경로를 한국어로 드러내며, 개발자 패널에서 모델 상태와 최근 오류를 확인할 수 있다.

## 완료 항목

- Dart `MethodChannel` 브릿지에 초기화 타임아웃과 상세 상태 모델을 추가했다.
- Android Kotlin / iOS Swift 브릿지가 모델 경로 미설정, 파일 부재, 부분 준비, 초기화 실패를 구분해 상태를 반환하도록 보강했다.
- 홈 화면에 런타임 상태 카드와 개발자 정보 패널을 추가했다.
- 결과 카드에 직전 응답이 네이티브인지 템플릿 폴백인지 표시했다.
- 위젯 테스트를 확장해 런타임 상태 UI와 응답 경로 표기를 검증했다.

## 검증

- 모바일:
  - `flutter pub get`
  - `flutter analyze`
  - `flutter test`
- 백엔드:
  - `python3 -m pytest backend/tests`
  - `python3 -m ruff check backend/app backend/tests`
  - `python3 -m mypy backend/app`
- Guardrails:
  - `./scripts/check-openapi-drift.sh`
  - `./scripts/check_seed_source_consistency.py`
  - `./scripts/check-native-dependency-pins.sh --strict`
  - `./scripts/check-release-signing.sh`
  - `./scripts/validate-docs.sh`
  - `pre-commit run --all-files`

## 남은 리스크

- 실제 LiteRT/Gemma 모델을 올린 Android/iOS 네이티브 성공 경로는 여전히 기기 빌드 smoke와 실기기 검증이 추가로 필요하다.
- SQLite 암호화는 아직 설계 단계이며, 현재 저장 구조는 평문 저장이다.
- 검색은 여전히 brute-force이므로 데이터 규모가 커지면 ANN 전환이 필요하다.
