from __future__ import annotations

from backend.app.repositories.seed_record_repository import SeedRecordRepository
from backend.app.services.curation_service import CurationService


def test_curation_service_prioritizes_relevant_seed_records() -> None:
    service = CurationService(SeedRecordRepository())

    response = service.curate("요즘 계속 지치고 무기력해요", top_k=2)

    assert response.supporting_records
    assert response.supporting_records[0].id in {
        "diary-burnout-feb-2024",
        "diary-burnout-nov-2024",
    }
    assert "회복" in response.summary or "산책" in response.answer


def test_curation_service_returns_empty_match_guidance_when_needed() -> None:
    service = CurationService(SeedRecordRepository())

    response = service.curate("천문학 사진 정리 방법이 궁금해요", top_k=2)

    assert response.supporting_records == []
    assert response.insight_title == "연결할 기록이 부족합니다"
