"""AI Learning Memory & User Privacy Controls (Export, Reset, Delete Recordings, Toggle Memory)."""
from __future__ import annotations

import json
from datetime import datetime, timezone

from fastapi import APIRouter, Depends

from app.database.db import db
from app.models.schemas import MemoryPrivacyUpdate
from app.security.auth_utils import get_current_user_id

router = APIRouter(prefix="/memory", tags=["AI Memory & Privacy"])


@router.get("")
def get_memory_profile(user_id: str = Depends(get_current_user_id)) -> dict:
    with db.connect() as conn:
        user = conn.execute(
            "SELECT english_level, memory_enabled, store_recordings FROM users WHERE id = ?",
            (user_id,),
        ).fetchone()
        mem = conn.execute("SELECT * FROM learning_memory WHERE user_id = ?", (user_id,)).fetchone()
    return {
        "memory_enabled": bool(user["memory_enabled"]) if user else True,
        "store_recordings": bool(user["store_recordings"]) if user else False,
        "proficiency_estimate": mem["proficiency_estimate"] if mem else "B1",
        "grammar_mistakes": json.loads(mem["grammar_mistakes_json"] or "[]") if mem else [],
        "pronunciation_issues": json.loads(mem["pronunciation_issues_json"] or "[]") if mem else [],
        "completed_exercises": json.loads(mem["completed_exercises_json"] or "[]") if mem else [],
        "session_summaries": json.loads(mem["session_summaries_json"] or "[]") if mem else [],
        "total_speaking_seconds": mem["total_speaking_seconds"] if mem else 0,
    }


@router.patch("/privacy")
def update_privacy(payload: MemoryPrivacyUpdate, user_id: str = Depends(get_current_user_id)) -> dict:
    now = datetime.now(timezone.utc).isoformat()
    with db.connect() as conn:
        if payload.memory_enabled is not None:
            conn.execute(
                "UPDATE users SET memory_enabled = ?, updated_at = ? WHERE id = ?",
                (int(payload.memory_enabled), now, user_id),
            )
        if payload.store_recordings is not None:
            conn.execute(
                "UPDATE users SET store_recordings = ?, updated_at = ? WHERE id = ?",
                (int(payload.store_recordings), now, user_id),
            )
    return get_memory_profile(user_id)


@router.get("/export")
def export_learning_history(user_id: str = Depends(get_current_user_id)) -> dict:
    with db.connect() as conn:
        user = conn.execute(
            "SELECT id, email, display_name, english_level, learning_goal, preferred_accent FROM users WHERE id = ?",
            (user_id,),
        ).fetchone()
        convs = conn.execute("SELECT * FROM conversations WHERE user_id = ?", (user_id,)).fetchall()
        vocab = conn.execute("SELECT * FROM user_vocabulary_progress WHERE user_id = ?", (user_id,)).fetchall()
        pron = conn.execute("SELECT * FROM pronunciation_attempts WHERE user_id = ?", (user_id,)).fetchall()
        gram = conn.execute("SELECT * FROM grammar_attempts WHERE user_id = ?", (user_id,)).fetchall()
    return {
        "exported_at": datetime.now(timezone.utc).isoformat(),
        "profile": dict(user) if user else {},
        "conversations": [dict(c) for c in convs],
        "vocabulary_progress": [dict(v) for v in vocab],
        "pronunciation_attempts": [dict(p) for p in pron],
        "grammar_attempts": [dict(g) for g in gram],
    }


@router.delete("/recordings")
def delete_stored_recordings(user_id: str = Depends(get_current_user_id)) -> dict:
    with db.connect() as conn:
        res = conn.execute(
            """
            UPDATE messages SET audio_path = ''
            WHERE conversation_id IN (SELECT id FROM conversations WHERE user_id = ?)
              AND audio_path != ''
            """,
            (user_id,),
        )
    return {"deleted_recordings_count": res.rowcount}


@router.post("/reset")
def reset_learning_progress(user_id: str = Depends(get_current_user_id)) -> dict:
    now = datetime.now(timezone.utc).isoformat()
    with db.connect() as conn:
        conn.execute("DELETE FROM conversations WHERE user_id = ?", (user_id,))
        conn.execute("DELETE FROM user_vocabulary_progress WHERE user_id = ?", (user_id,))
        conn.execute("DELETE FROM pronunciation_attempts WHERE user_id = ?", (user_id,))
        conn.execute("DELETE FROM grammar_attempts WHERE user_id = ?", (user_id,))
        conn.execute(
            """
            UPDATE learning_memory
            SET grammar_mistakes_json = '[]',
                pronunciation_issues_json = '[]',
                completed_exercises_json = '[]',
                session_summaries_json = '[]',
                total_speaking_seconds = 0,
                updated_at = ?
            WHERE user_id = ?
            """,
            (now, user_id),
        )
    return {"status": "reset_complete", "reset_at": now}
