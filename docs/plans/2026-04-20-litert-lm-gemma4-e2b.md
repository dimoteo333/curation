# 2026-04-20 LiteRT-LM Gemma 4 E2B Plan

## Goal

Enable the mobile app to run the curation generation path with the Gemma 4 E2B
family on-device through Google's LiteRT-LM runtime where the public SDK is
actually available, while keeping the existing API contract and the Flutter
orchestration layer stable.

## Verified constraints

- The current repository already uses a Flutter `MethodChannel` bridge for
  on-device generation, so the safest integration is to swap the Android native
  runtime behind the existing bridge instead of redesigning the Dart API.
- Google AI Edge now recommends LiteRT-LM over the deprecated MediaPipe Android
  `LLM Inference API`.
- The official LiteRT-LM Kotlin API is public and stable for Android.
- The public LiteRT-LM Swift API is still marked "In Dev / Coming Soon", so a
  production-quality Swift LiteRT-LM integration path is not documented yet.
- Google AI Edge Gallery's current Android model allowlist includes
  `gemma-4-E2B-it.litertlm`, while the public iOS allowlist does not expose the
  same Gemma 4 path.

## Scope

### In scope

- Replace the Android native bridge implementation from MediaPipe
  `LlmInference` to LiteRT-LM `Engine` + `Conversation`.
- Keep the existing Flutter bridge method names and response shape so the
  domain/UI layer stays compatible.
- Stage Gemma 4 E2B as a side-loaded `.litertlm` file path, documented for
  developers.
- Make iOS status/reporting explicit when Gemma 4 LiteRT-LM is requested but
  only the public fallback path is available.
- Update tests and docs to reflect the new Android runtime and model
  expectations.

### Out of scope

- Bundling a multi-GB Gemma model inside the repository.
- Shipping an undocumented private Swift/C++ LiteRT-LM integration path for
  iOS.
- Replacing the existing Dart semantic embedding fallback in this task.

## Implementation steps

1. Update the Android app dependency and manifest requirements for LiteRT-LM.
2. Rewrite the Android bridge handler around LiteRT-LM `Engine` lifecycle and a
   one-shot `Conversation` generation flow.
3. Preserve Dart-facing status semantics while surfacing backend/runtime detail
   useful for verification.
4. Update iOS bridge messaging to avoid claiming Gemma 4 LiteRT-LM support that
   is not publicly documented.
5. Update settings hints, architecture docs, and runbooks for `.litertlm`
   staging and platform support boundaries.
6. Run repository validation, Android build validation, iOS simulator build
   validation, and native dependency pin checks.

## Risk notes

- Android GPU initialization can still fail on unsupported devices, so the
  bridge should degrade to CPU rather than fail the whole on-device path.
- LiteRT-LM `engine.initialize()` can take several seconds, so existing
  timeout/fallback behavior on the Dart side must remain intact.
- iOS may still compile with the existing MediaPipe bridge, but it should no
  longer imply that Gemma 4 LiteRT-LM is available there.

## References

- https://github.com/google-ai-edge/LiteRT-LM
- https://ai.google.dev/edge/litert-lm/android
- https://github.com/google-ai-edge/gallery
- https://huggingface.co/google/gemma-4-E2B

## Progress log

- 2026-04-20: Re-read architecture, contracts, contributing, and guardrail docs
  before touching the implementation.
- 2026-04-20: Verified the current repository still uses MediaPipe on both
  native bridges behind the Flutter `MethodChannel`.
- 2026-04-20: Confirmed from official LiteRT-LM sources and Edge Gallery that
  Android has a stable public SDK and Gemma 4 E2B LiteRT-LM artifact, while the
  public Swift path is not yet ready for the same integration.
- 2026-04-20: Swapped the Android bridge from MediaPipe `LlmInference` to
  LiteRT-LM `Engine`/`Conversation`, keeping the existing Flutter bridge method
  contract intact.
- 2026-04-20: Pinned Android native dependencies to `litertlm-android 0.10.2`,
  added the recommended GPU native-library manifest declarations, and updated
  ProGuard keep rules for LiteRT-LM classes.
- 2026-04-20: Updated iOS bridge reporting so `.litertlm` Gemma 4 paths are
  reported as unsupported in the public SDK state instead of pretending native
  support exists.
- 2026-04-20: Updated settings and architecture/runbook docs to point
  developers at `gemma-4-E2B-it.litertlm` and document the Android-only public
  LiteRT-LM path.
- 2026-04-20: Verified iOS alternatives beyond Swift: Python is not documented
  for iOS app embedding, while a LiteRT-LM C++ iOS source-build path appears
  technically viable but is not yet integrated into this repository.
- 2026-04-20: Validation passed for `flutter pub get`, `flutter analyze`,
  `flutter test`, `flutter build apk --debug`, `flutter build ios --simulator
  --no-codesign`, `flutter test integration_test/tab_screenshots_test.dart -d
  0B614D8F-F114-412A-A72A-BEB8247D502B`, `python -m pytest backend/tests`,
  `python -m ruff check backend/app backend/tests`, `python -m mypy
  backend/app`, `./scripts/export-openapi.sh`, `./scripts/validate-docs.sh`,
  and `./scripts/check-native-dependency-pins.sh --strict`.
