from __future__ import annotations

from typing import Protocol

from backend.app.db.models import StoredRecord


class RecordRepository(Protocol):
    def list_records(self) -> list[StoredRecord]:
        """Return records available for curation."""
