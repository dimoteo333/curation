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
    assert response.insight_title
    assert "기록은" in response.summary
    assert "회복 단서" in response.answer or "우선순위" in response.answer


def test_curation_service_surfaces_sleep_context_with_grounded_summary() -> None:
    service = CurationService(SeedRecordRepository())

    response = service.curate("잠이 뒤집혀서 하루 종일 멍해요", top_k=2)

    assert response.supporting_records
    assert response.supporting_records[0].id in {
        "diary-routine-reset-2023",
        "diary-sleep-apr-2024",
    }
    assert "수면" in response.insight_title
    assert "생활 리듬" in response.summary or "새벽 세 시" in response.answer


def test_curation_service_returns_empty_match_guidance_when_needed() -> None:
    service = CurationService(SeedRecordRepository())

    response = service.curate("천문학 사진 정리 방법이 궁금해요", top_k=2)

    assert response.supporting_records == []
    assert response.insight_title == "연결할 기록이 부족합니다"
