# 2026-04-17 Sprint 2 Plan: Semantic Embeddings + Search Quality

## Scope

- Replace the current hash-based fallback embedding path with a pure Dart semantic embedding service tuned for Korean personal-record search.
- Improve on-device retrieval quality and fallback generation quality without breaking the existing API contract.
- Add retrieval caching so repeated local searches avoid unnecessary normalization and full rescans.
- Refine the runtime status UI so users can distinguish native vs fallback embedding/runtime states.
- Update architecture and guardrail-facing docs to reflect the new fallback strategy.

## Non-goals

- No backend API contract changes.
- No schema migration or destructive data rewrite.
- No native model bundle changes or signing/profile changes.

## Implementation Plan

1. Add `SemanticEmbeddingService` in Dart:
   - Korean token + character n-gram analysis
   - curated emotion/situation keyword clusters
   - TF-IDF style lexical weighting plus semantic cluster expansion
2. Switch the LiteRT embedder fallback from `KeywordHashEmbeddingService` to the new semantic service.
3. Improve `VectorDb`:
   - normalized document vector cache
   - normalized query cache
   - repeated query result cache
4. Improve fallback `LlmEngine` response quality:
   - richer use of tags and excerpts
   - time-aware phrasing
   - varied response patterns and follow-up prompts
5. Refine runtime UI:
   - explicit LLM state and embedding state
   - fallback guidance when semantic embedding fallback is active
6. Add regression tests for semantic retrieval quality and fallback response behavior.

## Validation Gates

- `cd mobile && flutter analyze`
- `cd mobile && flutter test`
- `python3 -m pytest backend/tests -q`
- `python3 -m ruff check backend/app backend/tests`
- `python3 -m mypy backend/app`
- `./scripts/export-openapi.sh`
- `bash scripts/validate-docs.sh`

## Progress

- Completed:
  - Added `SemanticEmbeddingService` and switched the LiteRT embedder fallback from hash vectors to Korean semantic concept + lexical embeddings.
  - Added normalized query cache, decoded vector cache, and repeated search result cache in `VectorDb`.
  - Improved fallback `LlmEngine` responses with tag-rich phrasing, relative time context, and theme-aware follow-up prompts.
  - Refined runtime UI to show separate LLM and embedding states plus semantic fallback guidance.
  - Added regression tests for burnout/sleep retrieval, low-score unrelated queries, cache reuse, and fallback response quality.

## Validation Result

- `cd mobile && flutter pub get`
- `cd mobile && flutter analyze`
- `cd mobile && flutter test`
- `python3 -m pytest backend/tests -q`
- `python3 -m ruff check backend/app backend/tests`
- `python3 -m mypy backend/app`
- `./scripts/export-openapi.sh`
- `bash scripts/validate-docs.sh`
