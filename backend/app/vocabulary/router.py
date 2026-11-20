"""Vocabulary & SM-2 Spaced Repetition endpoints."""
from __future__ import annotations

from datetime import datetime, timedelta, timezone

from fastapi import APIRouter, Depends, HTTPException

from app.database.db import db
from app.models.schemas import VocabFavoriteRequest, VocabReviewRequest
from app.security.auth_utils import get_current_user_id

router = APIRouter(prefix="/vocabulary", tags=["Vocabulary & SRS"])


def compute_sm2(easiness: float, interval: int, repetitions: int, quality: int) -> tuple[float, int, int]:
    """Standard SuperMemo-2 spaced repetition update."""
    if quality < 3:
        new_reps = 0
        new_interval = 1
    else:
        if repetitions == 0:
            new_interval = 1
        elif repetitions == 1:
            new_interval = 6
        else:
            new_interval = round(interval * easiness)
        new_reps = repetitions + 1
    new_ef = easiness + (0.1 - (5 - quality) * (0.08 + (5 - quality) * 0.02))
    new_ef = max(1.3, round(new_ef, 2))
    return new_ef, new_interval, new_reps


@router.get("")
def list_vocabulary(
    cefr_level: str | None = None,
    category: str | None = None,
    user_id: str = Depends(get_current_user_id),
) -> list[dict]:
    query = """
        SELECT v.*, COALESCE(p.is_favorite, 0) AS is_favorite,
               COALESCE(p.repetitions, 0) AS repetitions,
               COALESCE(p.interval_days, 1) AS interval_days,
               COALESCE(p.next_review_at, '') AS next_review_at
        FROM vocabulary_items v
        LEFT JOIN user_vocabulary_progress p
          ON v.id = p.vocab_id AND p.user_id = ?
        WHERE 1=1
    """
    params: list = [user_id]
    if cefr_level:
        query += " AND v.cefr_level = ?"
        params.append(cefr_level)
    if category:
        query += " AND v.category = ?"
        params.append(category)
    query += " ORDER BY v.cefr_level ASC, v.word ASC"
    with db.connect() as conn:
        rows = conn.execute(query, params).fetchall()
    return [dict(r) for r in rows]


@router.post("/{vocab_id}/review")
def review_word(vocab_id: str, payload: VocabReviewRequest, user_id: str = Depends(get_current_user_id)) -> dict:
    now = datetime.now(timezone.utc)
    with db.connect() as conn:
        vocab = conn.execute("SELECT id, word FROM vocabulary_items WHERE id = ?", (vocab_id,)).fetchone()
        if not vocab:
            raise HTTPException(status_code=404, detail="Vocabulary item not found")
        prog = conn.execute(
            "SELECT * FROM user_vocabulary_progress WHERE user_id = ? AND vocab_id = ?",
            (user_id, vocab_id),
        ).fetchone()

        ef = prog["easiness_factor"] if prog else 2.5
        interval = prog["interval_days"] if prog else 1
        reps = prog["repetitions"] if prog else 0
        fav = prog["is_favorite"] if prog else 0

        new_ef, new_interval, new_reps = compute_sm2(ef, interval, reps, payload.quality)
        next_review = (now + timedelta(days=new_interval)).isoformat()

        conn.execute(
            """
            INSERT INTO user_vocabulary_progress
            (user_id, vocab_id, is_favorite, easiness_factor, interval_days, repetitions, next_review_at, last_reviewed_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ON CONFLICT(user_id, vocab_id) DO UPDATE SET
                easiness_factor = excluded.easiness_factor,
                interval_days = excluded.interval_days,
                repetitions = excluded.repetitions,
                next_review_at = excluded.next_review_at,
                last_reviewed_at = excluded.last_reviewed_at
            """,
            (user_id, vocab_id, fav, new_ef, new_interval, new_reps, next_review, now.isoformat()),
        )

    return {
        "vocab_id": vocab_id,
        "word": vocab["word"],
        "easiness_factor": new_ef,
        "interval_days": new_interval,
        "repetitions": new_reps,
        "next_review_at": next_review,
    }


@router.post("/{vocab_id}/favorite")
def toggle_favorite(vocab_id: str, payload: VocabFavoriteRequest, user_id: str = Depends(get_current_user_id)) -> dict:
    now = datetime.now(timezone.utc).isoformat()
    with db.connect() as conn:
        vocab = conn.execute("SELECT id FROM vocabulary_items WHERE id = ?", (vocab_id,)).fetchone()
        if not vocab:
            raise HTTPException(status_code=404, detail="Vocabulary item not found")
        conn.execute(
            """
            INSERT INTO user_vocabulary_progress (user_id, vocab_id, is_favorite, next_review_at)
            VALUES (?, ?, ?, ?)
            ON CONFLICT(user_id, vocab_id) DO UPDATE SET is_favorite = excluded.is_favorite
            """,
            (user_id, vocab_id, int(payload.is_favorite), now),
        )
    return {"vocab_id": vocab_id, "is_favorite": payload.is_favorite}
