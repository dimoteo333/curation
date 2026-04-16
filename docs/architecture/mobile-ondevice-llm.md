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
  - Responsible for document indexing, local similarity search, and retrieval ordering.
- `TextEmbeddingService`
  - Prefers the native embedder bridge when an embedder model is staged locally.
  - Falls back to a deterministic hash embedder for tests and developer machines without model assets.
- `LlmEngine`
  - Builds the Korean system prompt and RAG template from `README.md`.
  - Prefers the native LiteRT bridge when an LLM model is staged locally.
  - Falls back to a deterministic local template generator so the repository stays runnable in CI.

### Native bridge

- Channel: `com.curator.curator_mobile/litert_lm`
- Methods:
  - `prepare`
  - `status`
  - `embed`
  - `generate`
- Android target:
  - `com.google.mediapipe:tasks-genai`
  - `com.google.mediapipe:tasks-text`
- iOS target:
  - `MediaPipeTasksGenAI`
  - `MediaPipeTasksGenAIC`
  - `MediaPipeTasksText`

## Model staging strategy

- Large production models are not committed into this repository.
- Developers stage model files out of repo and pass absolute paths through:
  - `--dart-define=LLM_MODEL_PATH=/abs/path/to/model`
  - `--dart-define=EMBEDDER_MODEL_PATH=/abs/path/to/embedder.tflite`
- The bridge stays path-based so it can accept:
  - LiteRT-LM style bundles such as `.litertlm`
  - MediaPipe `.task` packages
  - iOS-compatible `.bin` bundles where required by the native runtime

## Retrieval pipeline

1. Seed or import local `LifeRecord` documents.
2. Generate embeddings locally.
3. Store documents plus vectors in SQLite.
4. Embed the user question locally.
5. Retrieve top-k similar records.
6. Render a Korean RAG prompt.
7. Run generation on-device.
8. Return Korean UI text and linked supporting records.

## Current repository compromise

- The repository includes a deterministic local fallback for embedding and generation so `flutter test` and `flutter analyze` remain stable without shipping a multi-GB model artifact.
- When native model paths are configured on a real device, the same orchestration path can switch to the native LiteRT / MediaPipe runtime without changing the Flutter UI layer.
