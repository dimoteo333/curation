from __future__ import annotations

from collections.abc import Sequence

from backend.app.db.models import StoredRecord
from backend.app.db.seed_records import SEEDED_RECORDS


class SeedRecordRepository:
    def __init__(self, records: Sequence[StoredRecord] | None = None) -> None:
        self._records = list(records or SEEDED_RECORDS)

    def list_records(self) -> list[StoredRecord]:
        return sorted(self._records, key=lambda record: record.created_at, reverse=True)
