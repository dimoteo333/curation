# Mobile On-Device LLM Architecture

## Goal

Move the primary mobile curation path from backend-backed lookup to an on-device RAG flow that stays inside the Flutter app and native mobile runtimes.

## Bridge choice

- Flutter integration uses `MethodChannel`, not Dart FFI.
- Reason: the current Google AI Edge runtime guidance exposes a stable Android
  LiteRT-LM Kotlin SDK, but no first-party Flutter wrapper and no public
  production-ready Swift LiteRT-LM guide for the same Gemma 4 path.
- The Dart side owns orchestration and storage; Android and iOS own model loading and inference.

## Runtime split

### Dart / Flutter

- `VectorDb`
  - SQLite-backed local store for documents and embeddings.
  - Responsible for document indexing, local similarity search, retrieval ordering, and normalized-query/result caching for repeated lookups.
- `TextEmbeddingService`
  - Currently uses the pure Dart semantic embedder on both iOS and Android.
  - The native `embed` bridge remains intentionally unavailable until the MediaPipe text embedding path is stable on both platforms.
  - Uses Korean emotion/situation keyword concepts plus lexical weighting so fallback retrieval still preserves useful semantic similarity.
- `LlmEngine`
  - Builds the Korean system prompt and RAG template from `README.md`.
  - Prefers the native LiteRT bridge when an LLM model is staged locally.
  - Falls back to a deterministic but richer local template generator that reflects tags, excerpts, and relative time context so the repository stays runnable in CI.
- `onDeviceRuntimeStatusProvider`
  - Calls bridge `prepare` with both model paths at app startup.
  - Feeds the home screen runtime badge and developer panel.
  - Surfaces partial-ready, timeout, missing-file, and fallback states in Korean UI text.

### Native bridge

- Channel: `com.curator.curator_mobile/litert_lm`
- Methods:
  - `prepare`
  - `status`
  - `embed`
  - `generate`
- Android target:
  - `com.google.ai.edge.litertlm:litertlm-android:0.10.2`
  - GPU-first initialization with CPU fallback
  - optional `libvndksupport.so` and `libOpenCL.so` manifest declarations for
    GPU runtime availability
- iOS target:
  - `MediaPipeTasksGenAI 0.10.21`
  - `MediaPipeTasksGenAIC 0.10.21`
  - The public LiteRT-LM Swift API is still not documented as stable, so iOS
    keeps the legacy MediaPipe path for non-`.litertlm` experiments and reports
    `.litertlm` Gemma 4 requests as fallback-only.
  - The official LiteRT-LM Python API is documented for Linux and macOS, not
    iOS app embedding.
  - LiteRT-LM C++ source builds include iOS Bazel configs, but this repository
    does not yet ship the source-built C++ bridge artifacts or Objective-C++
    integration needed to run Gemma 4 from the app.
  - `MediaPipeTasksText` is not currently available from CocoaPods trunk in
    this repository setup, so iOS text embedding remains on the Dart fallback
    path.

## Model staging strategy

- Large production models are not committed into this repository.
- Developers stage model files out of repo and pass absolute paths through:
  - `--dart-define=LLM_MODEL_PATH=/abs/path/to/model`
  - `--dart-define=EMBEDDER_MODEL_PATH=/abs/path/to/embedder.tflite`
- Recommended Android runtime artifact:
  - family source: `https://huggingface.co/google/gemma-4-E2B`
  - deployable LiteRT-LM bundle:
    `litert-community/gemma-4-E2B-it-litert-lm/gemma-4-E2B-it.litertlm`
- The bridge stays path-based so it can accept:
  - LiteRT-LM bundles such as `.litertlm`
  - legacy MediaPipe `.task` packages
  - iOS-compatible `.bin` bundles where required by the legacy native runtime
- Bridge initialization is capped with a Dart-side timeout so the UI can fail closed into a visible fallback state rather than hanging indefinitely.

## Retrieval pipeline

1. Seed or import local `LifeRecord` documents.
2. Generate embeddings locally.
3. Store documents plus normalized vectors in SQLite and persist whether an embedding is already normalized.
4. Cache decoded normalized document vectors plus tag/cluster buckets in memory after first load.
5. Embed the user question locally and cache repeated normalized queries.
6. Use exact-tag prefiltering first, expand candidates through tag clusters, and fall back to a bounded full scan only when the query shares no tags with the local corpus.
7. Cache repeated question rankings with an LRU query cache.
8. Render a Korean RAG prompt.
9. Run generation on-device.
10. Return Korean UI text and linked supporting records.

## Current repository compromise

- The repository includes a deterministic local semantic embedding fallback and a richer local generation fallback so `flutter test` and `flutter analyze` remain stable without shipping a multi-GB model artifact.
- When a native LLM model path is configured on Android, the same orchestration
  path can switch generation to the official LiteRT-LM runtime without changing
  the Flutter UI layer.
- On iOS, `.litertlm` Gemma 4 paths are surfaced as unsupported in the public
  SDK state and the app stays on the Dart generation fallback unless a
  separately supported legacy MediaPipe-compatible model is provided.
- The validated future iOS path is a source-built C++ bridge, not Python, but
  that path still requires artifact production, Objective-C++ glue, Xcode
  wiring, and dedicated simulator/device validation before it is safe to ship.
- Even when native generation is available, semantic embedding stays on the Dart fallback path on both platforms.
- The home screen now exposes:
  - current runtime status
  - native vs fallback embedding state
  - actual response path for the last answer
  - developer diagnostics for model readiness, fallback activation, and last runtime error
