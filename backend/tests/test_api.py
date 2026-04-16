from __future__ import annotations

from fastapi.testclient import TestClient

from backend.app.main import app


def test_health_endpoint_reports_seeded_records() -> None:
    client = TestClient(app)

    response = client.get("/health")

    assert response.status_code == 200
    assert response.json() == {"status": "ok", "record_count": 5}


def test_curation_query_returns_korean_curated_response() -> None:
    client = TestClient(app)

    response = client.post(
        "/api/v1/curation/query",
        json={"question": "나 요즘 왜 이렇게 무기력하지?", "top_k": 3},
    )

    payload = response.json()

    assert response.status_code == 200
    assert payload["insight_title"] == "최근 기록에서 반복된 흐름"
    assert payload["supporting_records"]
    assert any(record["id"] == "diary-burnout-feb-2024" for record in payload["supporting_records"])
    assert "무기력" in payload["answer"] or "지침" in payload["answer"]
