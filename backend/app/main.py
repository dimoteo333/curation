from __future__ import annotations

from fastapi import FastAPI

from backend.app.routers import curation, health

app = FastAPI(
    title="Curator API",
    version="0.1.0",
    description="Development harness API for the Curator Korean curation slice.",
)

app.include_router(health.router)
app.include_router(curation.router)
