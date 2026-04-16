from __future__ import annotations

from fastapi import APIRouter, Depends

from backend.app.repositories.seed_record_repository import SeedRecordRepository
from backend.app.schemas.curation import CurationQueryRequest, CurationQueryResponse
from backend.app.services.curation_service import CurationService

router = APIRouter(prefix="/api/v1/curation", tags=["curation"])


def get_curation_service() -> CurationService:
    return CurationService(SeedRecordRepository())


@router.post("/query", response_model=CurationQueryResponse)
def curate(
    request: CurationQueryRequest,
    service: CurationService = Depends(get_curation_service),
) -> CurationQueryResponse:
    return service.curate(question=request.question, top_k=request.top_k)
