from __future__ import annotations

from backend.app.repositories.seed_record_repository import SeedRecordRepository
from backend.app.services.curation_service import CurationService


def test_curation_service_prioritizes_relevant_seed_records() -> None:
    service = CurationService(SeedRecordRepository())

    response = service.curate("요즘 계속 지치고 무기력해요", top_k=2)

    assert len(response.supporting_records) == 2
    assert response.supporting_records[0].id == "diary-burnout-feb-2024"
    assert response.insight_title
    assert "야근이 길어지던 주간 회고" in response.summary
    assert any("회복" in record.relevance_reason for record in response.supporting_records)
    assert response.suggested_follow_up


def test_curation_service_keeps_related_topics_out_of_direct_clues() -> None:
    service = CurationService(SeedRecordRepository())

    response = service.curate("요즘 계속 지치고 무기력해요", top_k=1)

    assert len(response.supporting_records) == 1
    assert "질문과 직접 맞닿는 단서는 무기력" in response.summary
    assert "질문과 직접 맞닿는 단서는 수면" not in response.summary
    assert "관련 흐름은 수면" in response.summary
    assert "직접 맞닿는 수면" not in response.supporting_records[0].relevance_reason
    assert "회복 관련 흐름" in response.supporting_records[0].relevance_reason


def test_curation_service_surfaces_sleep_context_with_grounded_summary() -> None:
    service = CurationService(SeedRecordRepository())

    response = service.curate("잠이 뒤집혀서 하루 종일 멍해요", top_k=2)

    assert len(response.supporting_records) == 2
    assert response.supporting_records[0].id == "diary-routine-reset-2023"
    assert "수면" in response.insight_title
    assert "생활 리듬을 되돌린 날" in response.summary
    assert all("수면" in record.relevance_reason for record in response.supporting_records)
    assert "수면" in response.answer


def test_curation_service_returns_empty_match_guidance_when_needed() -> None:
    service = CurationService(SeedRecordRepository())

    response = service.curate("천문학 사진 정리 방법이 궁금해요", top_k=2)

    assert response.supporting_records == []
    assert response.insight_title == "연결할 기록이 부족합니다"
