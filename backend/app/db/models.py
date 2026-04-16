from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime


@dataclass(frozen=True)
class StoredRecord:
    id: str
    source: str
    title: str
    content: str
    created_at: datetime
    tags: tuple[str, ...]
