"""Pydantic v2 request and response schemas for TALKORA AI."""
from __future__ import annotations

from typing import Any, Literal
from pydantic import BaseModel, Field

CEFRLevel = Literal["A1", "A2", "B1", "B2", "C1", "C2"]


class RegisterRequest(BaseModel):
    email: str = Field(..., min_length=5, max_length=160)
    password: str = Field(..., min_length=6, max_length=128)
    display_name: str = Field(..., min_length=1, max_length=80)
    native_language: str = "Arabic"
    english_level: CEFRLevel = "B1"
    learning_goal: str = "Fluency"
    preferred_accent: str = "American"
    daily_target_minutes: int = Field(default=15, ge=5, le=180)
    explanation_language: str = "Arabic"


class LoginRequest(BaseModel):
    email: str
    password: str


class ProfileUpdateRequest(BaseModel):
    display_name: str | None = None
    native_language: str | None = None
    english_level: CEFRLevel | None = None
    learning_goal: str | None = None
    preferred_accent: str | None = None
    daily_target_minutes: int | None = Field(default=None, ge=5, le=180)
    explanation_language: str | None = None
    memory_enabled: bool | None = None
    store_recordings: bool | None = None


class UserProfile(BaseModel):
    id: str
    email: str
    display_name: str
    native_language: str
    english_level: str
    learning_goal: str
    preferred_accent: str
    daily_target_minutes: int
    explanation_language: str
    memory_enabled: bool
    store_recordings: bool


class AuthResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"
    user: UserProfile


class ConversationCreateRequest(BaseModel):
    title: str = "Free Conversation"
    mode: str = "free_conversation"
    topic: str = "Daily Life"


class ChatTurnRequest(BaseModel):
    message: str = Field(..., min_length=1, max_length=4000)
    include_arabic_translation: bool = True
    include_correction: bool = True


class GrammarCorrection(BaseModel):
    has_issue: bool = False
    original: str = ""
    corrected: str = ""
    explanation_en: str = ""
    explanation_ar: str = ""


class ChatTurnResponse(BaseModel):
    conversation_id: str
    user_message: str
    assistant_reply: str
    arabic_translation: str = ""
    correction: GrammarCorrection | None = None
    follow_up_suggestions: list[str] = Field(default_factory=list)
    ai_identity_notice: str = "TALKORA AI (AI Speaking Companion)"


class VocabReviewRequest(BaseModel):
    quality: int = Field(..., ge=0, le=5, description="SM-2 quality rating 0-5")


class VocabFavoriteRequest(BaseModel):
    is_favorite: bool


class PronunciationCheckRequest(BaseModel):
    target_text: str = Field(..., min_length=1, max_length=500)
    spoken_text: str = Field(..., min_length=1, max_length=500)
    accent: str = "American"


class GrammarSubmitRequest(BaseModel):
    lesson_id: str
    answers: dict[str, str]


class DailyChallengeSubmitRequest(BaseModel):
    challenge_id: str
    transcript: str = Field(..., min_length=5, max_length=4000)
    duration_seconds: int = Field(default=60, ge=1, le=1800)


class MemoryPrivacyUpdate(BaseModel):
    memory_enabled: bool | None = None
    store_recordings: bool | None = None


class KnowledgeSearchRequest(BaseModel):
    query: str = Field(..., min_length=1, max_length=500)
    collection: str = "vocabulary"
    limit: int = Field(default=5, ge=1, le=20)


def model_to_dict(model: BaseModel, exclude_none: bool = False) -> dict[str, Any]:
    if hasattr(model, "model_dump"):
        return model.model_dump(exclude_none=exclude_none)
    return model.dict(exclude_none=exclude_none)


def model_to_json(model: BaseModel) -> str:
    if hasattr(model, "model_dump_json"):
        return model.model_dump_json()
    return model.json()
