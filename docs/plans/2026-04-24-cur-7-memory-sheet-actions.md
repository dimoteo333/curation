# CUR-7 Memory Sheet Actions

## Scope

- Mobile presentation: `memory_sheet.dart`, answer/timeline entry points
- Mobile state: persistent excluded-record list for curation scope
- Mobile data: future-safe source metadata for exported/opened records

## Goal

- Replace memory sheet action stubs with minimum working behavior.
- Keep API contracts unchanged.
- Avoid new plugin dependencies unless strictly required.

## Implementation Plan

1. Add a persisted excluded-record controller backed by `SharedPreferences`.
2. Extend `CurationQueryScope` so excluded record IDs affect on-device retrieval and cache keys.
3. Wire ask/follow-up curation requests to the current excluded-record state.
4. Convert memory sheet action buttons to real handlers:
   - Export: copy text/JSON payload to clipboard.
   - Exclude: persist the record ID in the exclude list and inform the user.
   - Open source: open a source-detail view with raw metadata and original content hints when direct deep-link info is unavailable.
5. Preserve current UI patterns and avoid backend or contract changes.

## Risks

- Existing imported file records do not persist an original file path, so direct source launch is not reliable for old data.
- Excluded records should affect future curation results, not silently mutate current response cards.
- SharedPreferences-backed state must stay simple to avoid analyzer/test regressions.

## Validation

- `dart analyze`
