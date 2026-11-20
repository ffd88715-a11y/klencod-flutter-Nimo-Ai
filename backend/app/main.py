"""TALKORA AI FastAPI Application Entrypoint."""
from __future__ import annotations

from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from app.api.router import api_router
from app.config import settings
from app.database.db import db
from app.knowledge.vector_store import vector_store
from app.security.rate_limit import RateLimitMiddleware
from app.services.seed_data import STARTER_VOCABULARY, seed_initial_data
from app.voice.ws_router import router as ws_router


def bootstrap_application() -> None:
    db.init_schema()
    seed_initial_data()
    vector_store.upsert(
        "vocabulary",
        [
            {
                "id": v["id"],
                "word": v["word"],
                "text": f"{v['word']} {v['english_definition']} {v['example_sentence']}",
                "cefr_level": v["cefr_level"],
            }
            for v in STARTER_VOCABULARY
        ],
    )


app = FastAPI(
    title=settings.app_name,
    version=settings.version,
    description="Self-hosted open-source AI voice conversation & English learning backend for TALKORA AI.",
)


@app.on_event("startup")
def _on_startup() -> None:
    bootstrap_application()


app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.cors_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
app.add_middleware(RateLimitMiddleware)

app.include_router(api_router)
app.include_router(ws_router)


@app.get("/health", tags=["System"])
def health_check() -> dict:
    return {
        "status": "ok",
        "service": settings.app_name,
        "version": settings.version,
        "llm_provider": settings.llm_provider,
        "stt_provider": settings.stt_provider,
        "tts_provider": settings.tts_provider,
    }
