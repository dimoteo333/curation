from __future__ import annotations

from fastapi import APIRouter, Depends

from backend.app.repositories.seed_record_repository import SeedRecordRepository
from backend.app.schemas.curation import HealthResponse
from backend.app.services.curation_service import HealthService

router = APIRouter(tags=["health"])


def get_health_service() -> HealthService:
    return HealthService(SeedRecordRepository())


@router.get("/health", response_model=HealthResponse)
def health(service: HealthService = Depends(get_health_service)) -> HealthResponse:
    return HealthResponse(**service.check())
