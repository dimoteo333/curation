#!/usr/bin/env python3
from __future__ import annotations

import re
import sys
from pathlib import Path


BACKEND_PATH = Path("backend/app/db/seed_records.py")
MOBILE_PATH = Path("mobile/lib/src/data/local/seed_records.dart")

SOURCE_MAP = {
    "diary": "일기",
    "calendar": "캘린더",
    "memo": "메모",
}


def parse_backend_records(text: str) -> dict[str, str]:
    pattern = re.compile(
        r'id="(?P<id>[^"]+)"[\s\S]*?source="(?P<source>[^"]+)"',
        re.MULTILINE,
    )
    return {match.group("id"): match.group("source") for match in pattern.finditer(text)}


def parse_mobile_records(text: str) -> dict[str, str]:
    pattern = re.compile(
        r"id: '([^']+)'[\s\S]*?source: '([^']+)'",
        re.MULTILINE,
    )
    return {record_id: source for record_id, source in pattern.findall(text)}


def main() -> int:
    backend_records = parse_backend_records(BACKEND_PATH.read_text(encoding="utf-8"))
    mobile_records = parse_mobile_records(MOBILE_PATH.read_text(encoding="utf-8"))

    errors: list[str] = []

    if backend_records.keys() != mobile_records.keys():
        errors.append(
            "Seed record IDs differ between backend and mobile: "
            f"backend={sorted(backend_records.keys())}, mobile={sorted(mobile_records.keys())}"
        )

    for record_id, backend_source in sorted(backend_records.items()):
        expected_mobile_source = SOURCE_MAP.get(backend_source)
        actual_mobile_source = mobile_records.get(record_id)
        if expected_mobile_source is None:
            errors.append(
                f"Backend source '{backend_source}' for record '{record_id}' is not mapped."
            )
            continue
        if actual_mobile_source != expected_mobile_source:
            errors.append(
                f"Record '{record_id}' source mismatch: backend='{backend_source}', "
                f"mobile='{actual_mobile_source}', expected mobile='{expected_mobile_source}'."
            )

    if errors:
        for error in errors:
            print(error)
        return 1

    print("Seed source consistency check passed")
    return 0


if __name__ == "__main__":
    sys.exit(main())
