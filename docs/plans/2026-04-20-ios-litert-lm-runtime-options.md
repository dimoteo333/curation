# 2026-04-20 iOS LiteRT-LM Runtime Options

## Goal

Validate whether the iOS app can run Gemma 4 through LiteRT-LM using Python or
C++ instead of the not-yet-public Swift SDK, and document or implement the
resulting decision safely.

## Verified findings

### Python

- The official LiteRT-LM Python guide states that the Python API is for Linux
  and macOS, with Windows support still upcoming.
- No public LiteRT-LM Python guide or iOS app integration path is documented.
- Conclusion:
  embedding Python inside the iOS app is not a public, supported LiteRT-LM app
  integration path for this repository.

### C++

- The official LiteRT-LM README marks the C++ API as stable.
- The source tree contains iOS Bazel configs such as `ios_arm64` and
  `ios_sim_arm64`, plus iOS prebuilt artifacts under `prebuilt/ios_*`.
- Local verification on this machine reached the iOS simulator C++ build path:
  `bazelisk build --config=ios_sim_arm64 //c:engine_cpu`
- The build did not fail on platform incompatibility. It failed while fetching
  and extracting dependencies because the local machine ran out of disk space.
- Conclusion:
  LiteRT-LM C++ appears technically buildable for iOS, but this repository does
  not yet include the source-built C++ artifacts, Objective-C++ bridge, Xcode
  wiring, or CI lane required to ship it safely.

## Decision

- Do not add a partial or guessed iOS C++ runtime integration in this turn.
- Keep the current iOS runtime on the validated fallback path.
- Update code and docs so iOS `.litertlm` status explains:
  - Python is not a public iOS LiteRT-LM path.
  - C++ is a source-build path that is not yet bundled into this app.

## Future implementation requirements

1. Produce stable LiteRT-LM C++ build artifacts for `ios_arm64` and
   `ios_sim_arm64`.
2. Add an Objective-C++ bridge layer callable from the Flutter iOS runner.
3. Wire the native libraries and headers into the Xcode project.
4. Add simulator and device validation for the C++ runtime path.
5. Decide whether source builds happen in CI or whether versioned artifacts are
   imported into the repo or release pipeline.

## Validation

- Official LiteRT-LM README language matrix
- Official LiteRT-LM Python guide
- Official LiteRT-LM source build guide
- Local Bazel verification of `ios_sim_arm64` C++ build path reaching toolchain
  and dependency resolution before failing on disk exhaustion

## References

- https://github.com/google-ai-edge/LiteRT-LM
- https://github.com/google-ai-edge/LiteRT-LM/blob/main/docs/api/python/getting_started.md
- https://github.com/google-ai-edge/LiteRT-LM/blob/main/docs/getting-started/build-and-run.md
