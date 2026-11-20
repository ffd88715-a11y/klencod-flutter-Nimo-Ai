"""Pronunciation analysis & phoneme-level mistake detection (aligned with SpeechOcean762 scoring concepts)."""
from __future__ import annotations

import json
import re
import uuid
from datetime import datetime, timezone
from difflib import SequenceMatcher

from fastapi import APIRouter, Depends

from app.database.db import db
from app.models.schemas import PronunciationCheckRequest
from app.security.auth_utils import get_current_user_id

router = APIRouter(prefix="/pronunciation", tags=["Pronunciation"])

ARABIC_LEARNER_PHONEME_TIPS = {
    "p": ("/p/ vs /b/", "Release a light puff of air for /p/ (as in 'practice', not 'bractice')."),
    "v": ("/v/ vs /f/", "Vibrate your vocal cords with upper teeth lightly touching the lower lip for /v/."),
    "th": ("/θ/ & /ð/", "Place the tip of your tongue gently between your teeth for 'th' sounds."),
    "r": ("/ɹ/", "Curl the tongue slightly back without tapping the roof of your mouth."),
}


def evaluate_pronunciation(target: str, spoken: str) -> dict:
    t_words = re.findall(r"[a-z']+", target.lower())
    s_words = re.findall(r"[a-z']+", spoken.lower())
    similarity = SequenceMatcher(None, t_words, s_words).ratio()
    overall = round(similarity * 100, 1)

    mistakes = []
    for idx, tw in enumerate(t_words):
        sw = s_words[idx] if idx < len(s_words) else ""
        word_ratio = SequenceMatcher(None, tw, sw).ratio()
        if word_ratio < 0.85:
            tip = "Focus on clear vowel stress and final consonant release."
            phoneme_tag = "word_match"
            for key, (tag, advice) in ARABIC_LEARNER_PHONEME_TIPS.items():
                if key in tw:
                    phoneme_tag = tag
                    tip = advice
                    break
            mistakes.append(
                {
                    "expected_word": tw,
                    "heard_word": sw or "(omitted)",
                    "phoneme_focus": phoneme_tag,
                    "tip": tip,
                }
            )

    return {
        "overall_score": overall,
        "fluency_label": "Excellent" if overall >= 90 else ("Good" if overall >= 75 else "Needs Practice"),
        "phoneme_mistakes": mistakes,
    }


@router.post("/evaluate")
def evaluate(payload: PronunciationCheckRequest, user_id: str = Depends(get_current_user_id)) -> dict:
    result = evaluate_pronunciation(payload.target_text, payload.spoken_text)
    now = datetime.now(timezone.utc).isoformat()
    attempt_id = str(uuid.uuid4())
    with db.connect() as conn:
        conn.execute(
            """
            INSERT INTO pronunciation_attempts
            (id, user_id, target_text, spoken_text, overall_score, phoneme_feedback_json, created_at)
            VALUES (?, ?, ?, ?, ?, ?, ?)
            """,
            (
                attempt_id,
                user_id,
                payload.target_text,
                payload.spoken_text,
                result["overall_score"],
                json.dumps(result["phoneme_mistakes"]),
                now,
            ),
        )
    return {"attempt_id": attempt_id, "target_text": payload.target_text, "spoken_text": payload.spoken_text, **result}
