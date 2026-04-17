# Sprint 7 Security And Privacy Plan

## Scope

- Mobile local persistence hardening only.
- No FastAPI contract changes.
- Docs updates for privacy posture and retention.

## Decisions

- Use application-level encryption rather than replacing `sqflite` with SQLCipher.
- Encrypt stored personal fields before SQLite persistence:
  - `title`
  - `content`
  - `tags_json`
  - `metadata_json`
- Keep embeddings unencrypted so local vector search behavior and schema shape stay compatible.
- Generate a random per-install master key on first launch.
- Store the master key in `flutter_secure_storage` so iOS uses Keychain and Android uses Keystore-backed storage.
- Derive the active AES key from the stored master key plus device context to avoid relying on device info as a secret.

## Migration

- Bump `VectorDb.schemaVersion` from `2` to `3`.
- Preserve the existing v1 -> v2 migration.
- Add a v2 -> v3 migration that rewrites plaintext local record fields to encrypted values in place.
- Imported file record IDs should stop embedding the original filename to reduce metadata leakage.

## Deletion Semantics

- Add `VectorDb.deleteAllData()` that closes the database and deletes the SQLite file plus sidecar files.
- `LifeRecordStore.deleteAllData()` should call `VectorDb.deleteAllData()` and clear `SharedPreferences`.
- Keep the encryption key in secure storage after deletion so future local data can be recreated without key churn.

## Validation

- Question input should be trimmed, control characters removed, and capped at 280 chars.
- Imported files must:
  - be `.txt` or `.md`
  - have a safe basename with no traversal/path separators
  - stay under a defined max size
  - decode as UTF-8 without malformed bytes

## Risks

- Existing plaintext rows are only protected after the v3 migration runs successfully.
- Settings deletion clears onboarding/runtime prefs, so the app may return to onboarding after confirmation.
- Application-level encryption protects stored text at rest but does not hide access patterns or embedding vectors.
