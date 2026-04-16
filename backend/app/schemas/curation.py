from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, Field


class CurationQueryRequest(BaseModel):
    question: str = Field(min_length=2, max_length=280, description="Korean user question")
    top_k: int = Field(default=3, ge=1, le=5, description="Maximum number of supporting records")


class SupportingRecordResponse(BaseModel):
    id: str
    source: str
    title: str
    created_at: datetime
    excerpt: str
    relevance_reason: str


class CurationQueryResponse(BaseModel):
    insight_title: str
    summary: str
    answer: str
    supporting_records: list[SupportingRecordResponse]
    suggested_follow_up: str


class HealthResponse(BaseModel):
    status: str
    record_count: int
