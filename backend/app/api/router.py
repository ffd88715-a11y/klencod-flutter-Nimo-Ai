"""Top-level API router aggregating all TALKORA AI domains."""
from fastapi import APIRouter

from app.auth.router import router as auth_router
from app.conversations.router import router as conversations_router
from app.learning.router import router as learning_router
from app.memory.router import router as memory_router
from app.pronunciation.router import router as pronunciation_router
from app.vocabulary.router import router as vocabulary_router

api_router = APIRouter(prefix="/api/v1")
api_router.include_router(auth_router)
api_router.include_router(conversations_router)
api_router.include_router(vocabulary_router)
api_router.include_router(pronunciation_router)
api_router.include_router(learning_router)
api_router.include_router(memory_router)
