# Mobile On-Device LLM Architecture

## Goal

Move the primary mobile curation path from backend-backed lookup to an on-device RAG flow that stays inside the Flutter app and native mobile runtimes.

## Bridge choice

- Flutter integration uses `MethodChannel`, not Dart FFI.
- Reason: the current Google AI Edge runtime guidance exposes Android and iOS SDKs for `LLM Inference API` and MediaPipe text embedding, but this repository does not have a first-party Flutter wrapper to depend on.
- The Dart side owns orchestration and storage; Android and iOS own model loading and inference.

## Runtime split

### Dart / Flutter

- `VectorDb`
  - SQLite-backed local store for documents and embeddings.
  - Responsible for document indexing, local similarity search, retrieval ordering, and normalized-query/result caching for repeated lookups.
- `TextEmbeddingService`
  - Prefers the native embedder bridge when an embedder model is staged locally.
  - Falls back to a pure Dart semantic embedder for tests and developer machines without model assets.
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
  - `com.google.mediapipe:tasks-genai:0.10.21`
  - `com.google.mediapipe:tasks-text:0.10.21`
- iOS target:
  - `MediaPipeTasksGenAI 0.10.21`
  - `MediaPipeTasksGenAIC 0.10.21`
  - `MediaPipeTasksText 0.10.21`

## Model staging strategy

- Large production models are not committed into this repository.
- Developers stage model files out of repo and pass absolute paths through:
  - `--dart-define=LLM_MODEL_PATH=/abs/path/to/model`
  - `--dart-define=EMBEDDER_MODEL_PATH=/abs/path/to/embedder.tflite`
- The bridge stays path-based so it can accept:
  - LiteRT-LM style bundles such as `.litertlm`
  - MediaPipe `.task` packages
  - iOS-compatible `.bin` bundles where required by the native runtime
- Bridge initialization is capped with a Dart-side timeout so the UI can fail closed into a visible fallback state rather than hanging indefinitely.

## Retrieval pipeline

1. Seed or import local `LifeRecord` documents.
2. Generate embeddings locally.
3. Store documents plus normalized vectors in SQLite.
4. Cache decoded normalized document vectors in memory after first load.
5. Embed the user question locally and cache repeated normalized queries.
6. Retrieve top-k similar records and cache repeated search results.
7. Render a Korean RAG prompt.
8. Run generation on-device.
9. Return Korean UI text and linked supporting records.

## Current repository compromise

- The repository includes a deterministic local semantic embedding fallback and a richer local generation fallback so `flutter test` and `flutter analyze` remain stable without shipping a multi-GB model artifact.
- When native model paths are configured on a real device, the same orchestration path can switch to the native LiteRT / MediaPipe runtime without changing the Flutter UI layer.
- The home screen now exposes:
  - current runtime status
  - native vs fallback embedding state
  - actual response path for the last answer
  - developer diagnostics for model readiness, fallback activation, and last runtime error
