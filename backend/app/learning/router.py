"""Grammar, Listening, Daily Speaking Challenge, Progress Analytics, and Knowledge Search endpoints."""
from __future__ import annotations

import json
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException

from app.database.db import db
from app.knowledge.vector_store import COLLECTIONS, vector_store
from app.llm.engine import analyze_grammar
from app.models.schemas import model_to_dict, model_to_json, DailyChallengeSubmitRequest, GrammarSubmitRequest, KnowledgeSearchRequest
from app.security.auth_utils import get_current_user_id
from app.services.seed_data import DAILY_CHALLENGES, GRAMMAR_LESSONS, LISTENING_LESSONS

router = APIRouter(prefix="/learning", tags=["Learning Modules"])


@router.get("/grammar")
def list_grammar_lessons() -> list[dict]:
    return GRAMMAR_LESSONS


@router.post("/grammar/submit")
def submit_grammar(payload: GrammarSubmitRequest, user_id: str = Depends(get_current_user_id)) -> dict:
    lesson = next((l for l in GRAMMAR_LESSONS if l["id"] == payload.lesson_id), None)
    if not lesson:
        raise HTTPException(status_code=404, detail="Grammar lesson not found")

    total = len(lesson["questions"])
    correct = 0
    mistakes = []
    for q in lesson["questions"]:
        user_ans = payload.answers.get(q["id"], "")
        if user_ans.strip().lower() == q["answer"].strip().lower():
            correct += 1
        else:
            mistakes.append(
                {
                    "question_id": q["id"],
                    "your_answer": user_ans,
                    "correct_answer": q["answer"],
                    "tip": q["tip"],
                }
            )
    score = round((correct / max(total, 1)) * 100, 1)
    now = datetime.now(timezone.utc).isoformat()
    with db.connect() as conn:
        conn.execute(
            "INSERT INTO grammar_attempts (id, user_id, lesson_id, score, mistakes_json, created_at) VALUES (?, ?, ?, ?, ?, ?)",
            (str(uuid.uuid4()), user_id, payload.lesson_id, score, json.dumps(mistakes), now),
        )
    return {"lesson_id": payload.lesson_id, "score": score, "correct": correct, "total": total, "mistakes": mistakes}


@router.get("/listening")
def list_listening_lessons() -> list[dict]:
    return LISTENING_LESSONS


@router.get("/daily-challenge")
def get_daily_challenge() -> dict:
    day_index = datetime.now(timezone.utc).timetuple().tm_yday % len(DAILY_CHALLENGES)
    return DAILY_CHALLENGES[day_index]


@router.post("/daily-challenge/submit")
def submit_daily_challenge(payload: DailyChallengeSubmitRequest, user_id: str = Depends(get_current_user_id)) -> dict:
    words = payload.transcript.split()
    word_count = len(words)
    wpm = round((word_count / max(payload.duration_seconds, 1)) * 60, 1)
    grammar_check = analyze_grammar(payload.transcript)
    fluency_score = min(100.0, round(60.0 + min(word_count, 80) * 0.5, 1))

    now = datetime.now(timezone.utc).isoformat()
    with db.connect() as conn:
        conn.execute(
            """
            UPDATE learning_memory
            SET total_speaking_seconds = total_speaking_seconds + ?, updated_at = ?
            WHERE user_id = ?
            """,
            (payload.duration_seconds, now, user_id),
        )
    return {
        "challenge_id": payload.challenge_id,
        "word_count": word_count,
        "words_per_minute": wpm,
        "fluency_score": fluency_score,
        "grammar_feedback": model_to_dict(grammar_check),
        "coach_note": "Strong pacing! Try connecting ideas with natural transitions like 'on top of that' or 'to be honest'.",
    }


@router.get("/progress")
def get_progress_dashboard(user_id: str = Depends(get_current_user_id)) -> dict:
    with db.connect() as conn:
        user = conn.execute("SELECT english_level, daily_target_minutes FROM users WHERE id = ?", (user_id,)).fetchone()
        mem = conn.execute("SELECT * FROM learning_memory WHERE user_id = ?", (user_id,)).fetchone()
        vocab_learned = conn.execute(
            "SELECT COUNT(*) AS c FROM user_vocabulary_progress WHERE user_id = ? AND repetitions >= 1",
            (user_id,),
        ).fetchone()["c"]
        conv_count = conn.execute("SELECT COUNT(*) AS c FROM conversations WHERE user_id = ?", (user_id,)).fetchone()["c"]
        avg_pron = conn.execute(
            "SELECT AVG(overall_score) AS a FROM pronunciation_attempts WHERE user_id = ?",
            (user_id,),
        ).fetchone()["a"]
        avg_gram = conn.execute(
            "SELECT AVG(score) AS a FROM grammar_attempts WHERE user_id = ?",
            (user_id,),
        ).fetchone()["a"]

    speaking_minutes = round((mem["total_speaking_seconds"] if mem else 0) / 60.0, 1)
    daily_target = user["daily_target_minutes"] if user else 15
    return {
        "english_level": user["english_level"] if user else "B1",
        "daily_target_minutes": daily_target,
        "speaking_minutes_total": speaking_minutes,
        "daily_progress_ratio": min(1.0, round(speaking_minutes / max(daily_target, 1), 2)),
        "vocabulary_learned": vocab_learned,
        "conversations_completed": conv_count,
        "average_pronunciation_score": round(avg_pron, 1) if avg_pron is not None else 0.0,
        "average_grammar_score": round(avg_gram, 1) if avg_gram is not None else 0.0,
        "streak_days": mem["streak_days"] if mem else 1,
    }


@router.post("/knowledge/search")
def search_knowledge(payload: KnowledgeSearchRequest) -> dict:
    if payload.collection not in COLLECTIONS:
        raise HTTPException(status_code=400, detail=f"Invalid collection. Allowed: {COLLECTIONS}")
    results = vector_store.search(payload.collection, payload.query, limit=payload.limit)
    return {"collection": payload.collection, "query": payload.query, "results": results}
