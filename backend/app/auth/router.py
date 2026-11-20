"""Authentication and User Profile endpoints."""
from __future__ import annotations

import uuid
from datetime import datetime, timezone

from fastapi import APIRouter, Depends, HTTPException, status

from app.database.db import db
from app.models.schemas import model_to_dict, model_to_json, AuthResponse, LoginRequest, ProfileUpdateRequest, RegisterRequest, UserProfile
from app.security.auth_utils import create_access_token, get_current_user_id, hash_password, verify_password

router = APIRouter(prefix="/auth", tags=["Authentication & Profile"])


def _row_to_profile(row) -> UserProfile:
    return UserProfile(
        id=row["id"],
        email=row["email"],
        display_name=row["display_name"],
        native_language=row["native_language"],
        english_level=row["english_level"],
        learning_goal=row["learning_goal"],
        preferred_accent=row["preferred_accent"],
        daily_target_minutes=row["daily_target_minutes"],
        explanation_language=row["explanation_language"],
        memory_enabled=bool(row["memory_enabled"]),
        store_recordings=bool(row["store_recordings"]),
    )


@router.post("/register", response_model=AuthResponse, status_code=status.HTTP_201_CREATED)
def register(payload: RegisterRequest) -> AuthResponse:
    now = datetime.now(timezone.utc).isoformat()
    user_id = str(uuid.uuid4())
    pw_hash = hash_password(payload.password)

    with db.connect() as conn:
        existing = conn.execute("SELECT id FROM users WHERE email = ?", (payload.email.lower(),)).fetchone()
        if existing:
            raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email is already registered")
        conn.execute(
            """
            INSERT INTO users (
                id, email, password_hash, display_name, native_language,
                english_level, learning_goal, preferred_accent, daily_target_minutes,
                explanation_language, memory_enabled, store_recordings, created_at, updated_at
            ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, 0, ?, ?)
            """,
            (
                user_id,
                payload.email.lower(),
                pw_hash,
                payload.display_name,
                payload.native_language,
                payload.english_level,
                payload.learning_goal,
                payload.preferred_accent,
                payload.daily_target_minutes,
                payload.explanation_language,
                now,
                now,
            ),
        )
        conn.execute(
            """
            INSERT INTO learning_memory (user_id, proficiency_estimate, updated_at)
            VALUES (?, ?, ?)
            """,
            (user_id, payload.english_level, now),
        )
        row = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()

    token = create_access_token(user_id, {"email": payload.email.lower()})
    return AuthResponse(access_token=token, user=_row_to_profile(row))


@router.post("/login", response_model=AuthResponse)
def login(payload: LoginRequest) -> AuthResponse:
    with db.connect() as conn:
        row = conn.execute("SELECT * FROM users WHERE email = ?", (payload.email.lower(),)).fetchone()
    if not row or not verify_password(payload.password, row["password_hash"]):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid email or password")
    token = create_access_token(row["id"], {"email": row["email"]})
    return AuthResponse(access_token=token, user=_row_to_profile(row))


@router.get("/profile", response_model=UserProfile)
def get_profile(user_id: str = Depends(get_current_user_id)) -> UserProfile:
    with db.connect() as conn:
        row = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    if not row:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="User not found")
    return _row_to_profile(row)


@router.patch("/profile", response_model=UserProfile)
def update_profile(payload: ProfileUpdateRequest, user_id: str = Depends(get_current_user_id)) -> UserProfile:
    updates = model_to_dict(payload, exclude_none=True)
    if not updates:
        return get_profile(user_id)
    if "memory_enabled" in updates:
        updates["memory_enabled"] = int(bool(updates["memory_enabled"]))
    if "store_recordings" in updates:
        updates["store_recordings"] = int(bool(updates["store_recordings"]))
    updates["updated_at"] = datetime.now(timezone.utc).isoformat()

    set_clause = ", ".join(f"{k} = ?" for k in updates)
    values = list(updates.values()) + [user_id]
    with db.connect() as conn:
        conn.execute(f"UPDATE users SET {set_clause} WHERE id = ?", values)
        row = conn.execute("SELECT * FROM users WHERE id = ?", (user_id,)).fetchone()
    return _row_to_profile(row)
