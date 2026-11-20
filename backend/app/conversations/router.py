"""Conversation session management and natural AI dialogue endpoints."""
from __future__ import annotations

import json
import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, Response, status

from app.database.db import db
from app.llm.engine import llm_engine
from app.models.schemas import model_to_dict, model_to_json, ChatTurnRequest, ChatTurnResponse, ConversationCreateRequest
from app.security.auth_utils import get_current_user_id

router = APIRouter(prefix="/conversations", tags=["Conversations"])


@router.post("", status_code=status.HTTP_201_CREATED)
def create_conversation(payload: ConversationCreateRequest, user_id: str = Depends(get_current_user_id)) -> dict:
    conv_id = str(uuid.uuid4())
    now = datetime.now(timezone.utc).isoformat()
    with db.connect() as conn:
        user = conn.execute("SELECT english_level FROM users WHERE id = ?", (user_id,)).fetchone()
        cefr = user["english_level"] if user else "B1"
        conn.execute(
            """
            INSERT INTO conversations (id, user_id, title, mode, topic, cefr_level, created_at, updated_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (conv_id, user_id, payload.title, payload.mode, payload.topic, cefr, now, now),
        )
    return {
        "id": conv_id,
        "title": payload.title,
        "mode": payload.mode,
        "topic": payload.topic,
        "cefr_level": cefr,
        "created_at": now,
    }


@router.get("")
def list_conversations(user_id: str = Depends(get_current_user_id)) -> list[dict]:
    with db.connect() as conn:
        rows = conn.execute(
            "SELECT * FROM conversations WHERE user_id = ? ORDER BY updated_at DESC",
            (user_id,),
        ).fetchall()
    return [dict(r) for r in rows]


@router.get("/{conversation_id}/messages")
def get_messages(conversation_id: str, user_id: str = Depends(get_current_user_id)) -> list[dict]:
    with db.connect() as conn:
        conv = conn.execute(
            "SELECT id FROM conversations WHERE id = ? AND user_id = ?",
            (conversation_id, user_id),
        ).fetchone()
        if not conv:
            raise HTTPException(status_code=404, detail="Conversation not found")
        rows = conn.execute(
            "SELECT * FROM messages WHERE conversation_id = ? ORDER BY created_at ASC",
            (conversation_id,),
        ).fetchall()
    return [dict(r) for r in rows]


@router.post("/{conversation_id}/turn", response_model=ChatTurnResponse)
async def send_turn(
    conversation_id: str,
    payload: ChatTurnRequest,
    user_id: str = Depends(get_current_user_id),
) -> ChatTurnResponse:
    now = datetime.now(timezone.utc).isoformat()
    with db.connect() as conn:
        conv = conn.execute(
            "SELECT * FROM conversations WHERE id = ? AND user_id = ?",
            (conversation_id, user_id),
        ).fetchone()
        if not conv:
            raise HTTPException(status_code=404, detail="Conversation not found")
        user_row = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
        mem_row = conn.execute("SELECT * FROM learning_memory WHERE user_id = ?", (user_id,)).fetchone()
        hist_rows = conn.execute(
            "SELECT role, content FROM messages WHERE conversation_id = ? ORDER BY created_at ASC LIMIT 20",
            (conversation_id,),
        ).fetchall()

    history = [{"role": r["role"], "content": r["content"]} for r in hist_rows]
    profile = dict(user_row)
    memory_context = ""
    if profile.get("memory_enabled") and mem_row:
        memory_context = f"Grammar focus: {mem_row['grammar_mistakes_json']}; Pronunciation: {mem_row['pronunciation_issues_json']}"

    result = await llm_engine.generate_reply(
        user_text=payload.message,
        history=history,
        profile=profile,
        memory_context=memory_context,
        topic=conv["topic"],
    )

    correction = result["correction"] if payload.include_correction else None
    arabic = result["arabic_translation"] if payload.include_arabic_translation else ""

    with db.connect() as conn:
        conn.execute(
            "INSERT INTO messages (id, conversation_id, role, content, created_at) VALUES (?, ?, 'user', ?, ?)",
            (str(uuid.uuid4()), conversation_id, payload.message, now),
        )
        conn.execute(
            """
            INSERT INTO messages (id, conversation_id, role, content, arabic_translation, correction_json, created_at)
            VALUES (?, ?, 'assistant', ?, ?, ?, ?)
            """,
            (
                str(uuid.uuid4()),
                conversation_id,
                result["reply"],
                arabic,
                model_to_json(correction) if correction else "",
                now,
            ),
        )
        conn.execute("UPDATE conversations SET updated_at = ? WHERE id = ?", (now, conversation_id))

        # Update personalized memory when enabled
        if profile.get("memory_enabled") and correction and correction.has_issue and mem_row:
            mistakes = json.loads(mem_row["grammar_mistakes_json"] or "[]")
            mistakes.append({"original": correction.original, "corrected": correction.corrected, "at": now})
            conn.execute(
                "UPDATE learning_memory SET grammar_mistakes_json = ?, updated_at = ? WHERE user_id = ?",
                (json.dumps(mistakes[-50:]), now, user_id),
            )

    return ChatTurnResponse(
        conversation_id=conversation_id,
        user_message=payload.message,
        assistant_reply=result["reply"],
        arabic_translation=arabic,
        correction=correction,
        follow_up_suggestions=result["follow_up_suggestions"],
    )


@router.delete("/{conversation_id}", status_code=status.HTTP_204_NO_CONTENT, response_class=Response)
def delete_conversation(conversation_id: str, user_id: str = Depends(get_current_user_id)):
    with db.connect() as conn:
        res = conn.execute(
            "DELETE FROM conversations WHERE id = ? AND user_id = ?",
            (conversation_id, user_id),
        )
        if res.rowcount == 0:
            raise HTTPException(status_code=404, detail="Conversation not found")
