# Android Release Runbook

## 목적

- 개발용 debug keystore와 실제 배포용 release keystore를 분리한다.
- 저장소에는 release keystore를 두지 않고, 로컬 또는 CI 비밀값으로만 주입한다.

## 현재 구성

- debug signing:
  - keystore 경로: `mobile/android/debug.keystore`
  - 기본 alias: `androiddebugkey`
  - 기본 비밀번호: `android`
- release signing:
  - 환경 변수 우선
  - `mobile/android/local.properties` 보조

## release signing 입력값

- 환경 변수:
  - `CURATOR_RELEASE_STORE_FILE`
  - `CURATOR_RELEASE_STORE_PASSWORD`
  - `CURATOR_RELEASE_KEY_ALIAS`
  - `CURATOR_RELEASE_KEY_PASSWORD`
- 또는 `mobile/android/local.properties`:

```properties
curator.release.storeFile=/absolute/path/to/curator-release.keystore
curator.release.storePassword=change-me
curator.release.keyAlias=curator-release
curator.release.keyPassword=change-me
```

## 실제 release keystore 생성 절차

1. 안전한 로컬 경로 또는 사내 비밀 저장소에 keystore를 생성한다.
2. 생성 예시:

```bash
keytool -genkeypair \
  -v \
  -keystore ~/secure/curator-release.keystore \
  -alias curator-release \
  -keyalg RSA \
  -keysize 4096 \
  -validity 3650
```

3. 생성된 keystore는 저장소에 커밋하지 않는다.
4. CI에서는 keystore 파일 자체를 base64로 인코딩해 secret으로 저장하고, 런타임에 복원한다.

## 로컬 release 빌드

```bash
cd mobile
flutter pub get
flutter build apk --release
```

## 가드레일

- `mobile/android/app/build.gradle.kts`의 `release`는 debug signing을 사용하면 안 된다.
- `./scripts/check-release-signing.sh`가 release debug signing drift를 차단한다.
