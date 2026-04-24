## Goal

Unify embedding tokenization and topic-detection rules so backend and mobile read the same source instead of maintaining duplicated hardcoded dictionaries and regexes.

## Scope

- Extract shared embedding rules into a versioned data file.
- Refactor backend curation topic detection to load the shared rules.
- Refactor mobile embedding/topic helpers to read the same rules from bundled assets.
- Preserve existing API contract and behavior.

## Plan

1. Inspect backend `curation_service.py` rule definitions and mobile embedding-related code for duplicated logic.
2. Define a shared JSON schema for topic aliases, token regex, and normalization settings.
3. Add backend loader/helpers around the shared rules and update curation service to use them.
4. Bundle the same JSON into mobile assets and update the relevant Dart code to load/use it.
5. Run focused validation, especially `python -m pytest backend/tests`, then export any contract/docs artifacts only if touched.

## Risks

- Regex portability between Python and Dart must remain compatible.
- Changing topic detection could subtly affect retrieval heuristics if normalization diverges.
- Asset loading on mobile must not introduce startup regressions or async ordering bugs.
