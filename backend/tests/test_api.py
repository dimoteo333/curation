from __future__ import annotations

import httpx
import pytest

from backend.app.main import app


@pytest.mark.anyio
async def test_health_endpoint_reports_seeded_records() -> None:
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(
        transport=transport,
        base_url="http://testserver",
    ) as client:
        response = await client.get("/health")

        assert response.status_code == 200
        assert response.json() == {"status": "ok", "record_count": 14}


@pytest.mark.anyio
async def test_curation_query_returns_korean_curated_response() -> None:
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(
        transport=transport,
        base_url="http://testserver",
    ) as client:
        response = await client.post(
            "/api/v1/curation/query",
            json={"question": "나 요즘 왜 이렇게 무기력하지?", "top_k": 3},
        )

        payload = response.json()

        assert response.status_code == 200
        assert payload["insight_title"]
        assert payload["supporting_records"]
        assert any(
            record["id"] == "diary-burnout-feb-2024"
            for record in payload["supporting_records"]
        )
        assert "무기력" in payload["answer"] or "회복 단서" in payload["answer"]
