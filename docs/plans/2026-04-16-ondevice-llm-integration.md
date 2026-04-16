# 2026-04-16 On-Device LLM Integration Plan

## Service goal

Replace the current rule-based mobile curation path with a Korean-first on-device retrieval and generation pipeline that runs locally on the phone, while keeping the FastAPI backend and existing API contract available for development and demo workflows.

## Scope constraints

- All inference and retrieval used by the mobile UX must remain on device.
- The backend API stays available for the development harness and contract validation, but mobile defaults to the on-device path.
- Korean UI, Korean prompt templates, and privacy requirements from `README.md` must remain intact.
- API contract compatibility remains additive only.

## Phase plan

### Phase A. Research and native bridge setup

Goal:
- Confirm the feasible LiteRT-LM integration path for Flutter.
- Establish a stable Dart-to-native interface for Android and iOS.

Milestones:
1. Confirm whether an official Flutter binding exists.
2. If not, define a `MethodChannel` bridge for LiteRT-LM / MediaPipe LLM Inference native runtimes.
3. Document model staging expectations for Gemma edge bundles.
4. Add Dart-side bridge contracts and native platform skeletons.

Acceptance criteria:
- The repository contains a bridge architecture document.
- Dart code defines a typed bridge interface for model status, model loading, embedding, and generation.
- Android and iOS contain minimal native bridge handlers that compile without requiring a bundled production model.

Validation:
- `cd mobile && flutter analyze`
- `cd mobile && flutter test`

### Phase B. On-device embeddings and vector store

Goal:
- Introduce a local document store and vector search path for mobile retrieval.

Milestones:
1. Add a SQLite-backed local store for documents and embeddings.
2. Implement a mobile embedding service abstraction.
3. Seed the existing curated records into the local store.
4. Expose a vector search API for the curation pipeline.

Acceptance criteria:
- `mobile/lib/src/data/local/vector_db.dart` exists and is covered by tests.
- Seed records can be indexed locally.
- Retrieval returns top-k relevant records for Korean prompts without network access.

Validation:
- `cd mobile && flutter test`
- `cd mobile && flutter analyze`

### Phase C. On-device LLM inference

Goal:
- Load a LiteRT-compatible Gemma model locally and run Korean prompt completion.

Milestones:
1. Add an `LlmEngine` service with prompt rendering based on `README.md`.
2. Wire the engine to the native bridge.
3. Add a model runtime configuration path for side-loaded or bundled models.

Acceptance criteria:
- `mobile/lib/src/domain/services/llm_engine.dart` exists.
- The engine builds Korean prompts from question plus retrieved context.
- The bridge can report actionable runtime diagnostics when the model is unavailable.

Validation:
- `cd mobile && flutter analyze`
- `cd mobile && flutter test`

### Phase D. RAG pipeline integration

Goal:
- Replace the rule-based mobile curation path with local retrieval plus generation.

Milestones:
1. Add a mobile orchestration service for query -> embedding -> retrieval -> prompt -> generation.
2. Switch the default mobile repository to the on-device implementation.
3. Keep the remote repository available for harness and demo fallback, but not as the default UX path.
4. Add integration coverage for the on-device flow.

Acceptance criteria:
- Mobile curation succeeds without backend access when a local engine is available.
- Existing UI renders the on-device result path in Korean.
- Backend API code remains available and contract-compatible.

Validation:
- `cd mobile && flutter test`
- `cd mobile && flutter analyze`
- `python3 -m pytest backend/tests -q`

### Phase E. Validation and optimization

Goal:
- Leave the repository in a runnable, documented state with explicit runtime tradeoffs.

Milestones:
1. Run the full repository validation suite.
2. Capture model/runtime profiling hooks and quantization expectations.
3. Update architecture docs, contracts, and runbooks as needed.
4. Commit and push the implementation.

Acceptance criteria:
- Required checks pass locally, or remaining environment-specific blockers are documented with exact commands and reasons.
- Documentation reflects the on-device mobile architecture.
- Plan progress and decision logs are current.

Validation:
- `python3 -m ruff check backend/app backend/tests`
- `python3 -m mypy backend/app`
- `python3 -m pytest backend/tests -q`
- `cd mobile && flutter analyze`
- `cd mobile && flutter test`
- `bash scripts/export-openapi.sh`
- `bash scripts/validate-docs.sh`

## Risks

- Google provides native Android and iOS on-device GenAI runtimes, but there does not appear to be an official Flutter wrapper in the referenced product docs, so Flutter integration likely needs a maintained platform-channel bridge.
- A production Gemma LiteRT-LM model is too large to commit into this repository; runtime model staging must be explicit and developer-friendly.
- A single model that is optimal for both embedding and generation may not be available in the same shipped artifact, so the initial retrieval path may need a separate text embedding model or a deterministic fallback until the native embedding path is ready.
- iOS pod and Android dependency resolution for edge runtimes can drift over time; versions need to remain explicit where possible.

## Open questions

- Which exact Gemma mobile artifact should be the default target: a LiteRT-LM `.litertlm` bundle, a `.task` bundle, or a side-loaded local directory?
- Should embeddings initially use a dedicated MediaPipe text embedder model or a Gemma-derived representation exposed by the native runtime?
- Do we want the app to block on missing local model assets, or present an explicit "model setup required" state with developer instructions?

## Research notes

- Google AI Edge lists the MediaPipe `LLM Inference API` as available on Android, Web, Python, and iOS, which supports using platform-native runtimes across both mobile platforms.
- Google AI docs include mobile deployment guidance for Gemma on Android and iOS, but no first-party Flutter wrapper was identified during this pass.
- MediaPipe text embedding docs show dedicated native Android/iOS task libraries for `.tflite` text embedding models, which makes a split generator/embedder architecture more practical than relying on a hidden-state export path from the generation runtime in the first implementation.

Reference links:
- https://ai.google.dev/edge/mediapipe/solutions/guide
- https://ai.google.dev/gemma/docs/integrations/mobile
- https://ai.google.dev/edge/mediapipe/solutions/text/text_embedder/ios

## Progress log

- 2026-04-16: Read `README.md`, current mobile/backend architecture docs, and the initial implementation plan to confirm the current rule-based slice and the privacy target state.
- 2026-04-16: Confirmed the repository currently defaults mobile to the backend-driven harness and needs a new mobile-local retrieval and generation path.
- 2026-04-16: Created the on-device LLM integration plan and captured the initial research direction for LiteRT-LM bridging.
- 2026-04-16: Added a Flutter `MethodChannel` bridge contract plus Android/iOS native bridge skeletons for LiteRT/MediaPipe runtime hookup.
- 2026-04-16: Added a SQLite-backed local vector store, seeded mobile records, and a local embedding abstraction with a deterministic fallback for test environments.
- 2026-04-16: Added a Korean prompt-building `LlmEngine` and switched the default mobile repository to an on-device retrieval-and-generation path.
- 2026-04-16: Updated mobile architecture docs to reflect the new on-device default and the retained remote harness mode.
- 2026-04-16: Full required validation passed for Ruff, mypy, backend pytest, Flutter analyze, Flutter test, OpenAPI export, and docs validation.
- 2026-04-16: Additional Android build verification with `flutter build apk --debug` is blocked on this machine because no Java Runtime is installed.

## Decision log

- 2026-04-16: Use a Flutter `MethodChannel` bridge rather than Dart FFI as the primary integration mechanism, because the supported Google mobile runtimes are exposed as native Android/iOS SDKs rather than a stable cross-platform C ABI in the referenced docs.
- 2026-04-16: Keep the backend harness intact and contract-compatible, but switch the mobile runtime toward an on-device default instead of extending backend dependence.
- 2026-04-16: Separate retrieval and generation interfaces so the app can adopt a dedicated on-device text embedding model if Gemma embedding extraction is not exposed cleanly by the native generation runtime.
- 2026-04-16: Keep a deterministic on-device fallback for retrieval and generation in CI and local development, because the repository does not ship a production Gemma model artifact and the validation suite must remain runnable without network model downloads.
