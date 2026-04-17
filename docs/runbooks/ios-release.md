# iOS Release Runbook

## 목적

- `큐레이터` iOS 릴리스 빌드와 수동 서명 절차를 일관되게 유지한다.
- CI는 unsigned archive까지만 만들고, 실제 배포 서명은 Apple 자격 증명이 있는 환경에서 수행한다.

## 현재 기준

- Bundle identifier: `com.curator.curatormobile`
- Version: `0.1.0`
- Build number: `1`
- Deployment target: iOS 16.0+
- Export options: `mobile/ios/exportOptions.plist`

## 서명 준비

1. Apple Developer에서 `com.curator.curatormobile` App ID를 생성한다.
2. App Store Connect에 앱 레코드를 만들고 번들 식별자를 연결한다.
3. 배포용 인증서와 App Store provisioning profile을 발급한다.
4. Xcode `Runner` target의 Team을 배포 계정으로 지정한다.

## 로컬 검증

```bash
cd mobile
flutter pub get
flutter build ios --simulator --debug --no-codesign
flutter build ios --release --no-codesign
```

## unsigned archive 생성

```bash
cd mobile
xcodebuild \
  -workspace ios/Runner.xcworkspace \
  -scheme Runner \
  -configuration Release \
  -archivePath build/ios/archive/Runner.xcarchive \
  archive \
  CODE_SIGNING_ALLOWED=NO \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGN_IDENTITY=""
```

## 수동 signing/export

1. Xcode Organizer에서 `Runner.xcarchive`를 연다.
2. `Distribute App` -> `App Store Connect` 또는 `Export`를 선택한다.
3. 수동 서명이 필요하면 `mobile/ios/exportOptions.plist`를 기준으로 provisioning profile과 team을 연결한다.
4. CLI export 예시:

```bash
xcodebuild \
  -exportArchive \
  -archivePath mobile/build/ios/archive/Runner.xcarchive \
  -exportPath mobile/build/ios/export \
  -exportOptionsPlist mobile/ios/exportOptions.plist
```

## CI secret 권장값

- `APPLE_TEAM_ID`
- `APP_STORE_CONNECT_ISSUER_ID`
- `APP_STORE_CONNECT_KEY_ID`
- `APP_STORE_CONNECT_PRIVATE_KEY`

이 저장소의 기본 release workflow는 unsigned archive만 생성한다. 실제 signing/upload lane이 필요해지면 위 비밀값과 provisioning profile 주입 단계를 별도 job으로 추가한다.
