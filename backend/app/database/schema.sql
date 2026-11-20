-- TALKORA AI — Production PostgreSQL 16 Schema
-- Compatible with PostgreSQL 16+ (and mapped to SQLite in local dev mode)

CREATE TABLE IF NOT EXISTS users (
    id TEXT PRIMARY KEY,
    email TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    display_name TEXT NOT NULL,
    native_language TEXT NOT NULL DEFAULT 'Arabic',
    english_level TEXT NOT NULL DEFAULT 'B1',
    learning_goal TEXT NOT NULL DEFAULT 'Fluency',
    preferred_accent TEXT NOT NULL DEFAULT 'American',
    daily_target_minutes INTEGER NOT NULL DEFAULT 15,
    explanation_language TEXT NOT NULL DEFAULT 'Arabic',
    memory_enabled INTEGER NOT NULL DEFAULT 1,
    store_recordings INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS conversations (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    mode TEXT NOT NULL DEFAULT 'free_conversation',
    topic TEXT NOT NULL DEFAULT 'Daily Life',
    cefr_level TEXT NOT NULL DEFAULT 'B1',
    summary TEXT DEFAULT '',
    duration_seconds INTEGER NOT NULL DEFAULT 0,
    created_at TEXT NOT NULL,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS messages (
    id TEXT PRIMARY KEY,
    conversation_id TEXT NOT NULL REFERENCES conversations(id) ON DELETE CASCADE,
    role TEXT NOT NULL CHECK (role IN ('user', 'assistant', 'system')),
    content TEXT NOT NULL,
    arabic_translation TEXT DEFAULT '',
    correction_json TEXT DEFAULT '',
    audio_path TEXT DEFAULT '',
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS vocabulary_items (
    id TEXT PRIMARY KEY,
    word TEXT NOT NULL UNIQUE,
    ipa TEXT NOT NULL,
    arabic_meaning TEXT NOT NULL,
    english_definition TEXT NOT NULL,
    example_sentence TEXT NOT NULL,
    cefr_level TEXT NOT NULL,
    category TEXT NOT NULL DEFAULT 'general',
    audio_hint TEXT DEFAULT ''
);

CREATE TABLE IF NOT EXISTS user_vocabulary_progress (
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    vocab_id TEXT NOT NULL REFERENCES vocabulary_items(id) ON DELETE CASCADE,
    is_favorite INTEGER NOT NULL DEFAULT 0,
    easiness_factor REAL NOT NULL DEFAULT 2.5,
    interval_days INTEGER NOT NULL DEFAULT 1,
    repetitions INTEGER NOT NULL DEFAULT 0,
    next_review_at TEXT NOT NULL,
    last_reviewed_at TEXT DEFAULT '',
    PRIMARY KEY (user_id, vocab_id)
);

CREATE TABLE IF NOT EXISTS pronunciation_attempts (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    target_text TEXT NOT NULL,
    spoken_text TEXT NOT NULL,
    overall_score REAL NOT NULL,
    phoneme_feedback_json TEXT NOT NULL,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS grammar_attempts (
    id TEXT PRIMARY KEY,
    user_id TEXT NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    lesson_id TEXT NOT NULL,
    score REAL NOT NULL,
    mistakes_json TEXT NOT NULL,
    created_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS learning_memory (
    user_id TEXT PRIMARY KEY REFERENCES users(id) ON DELETE CASCADE,
    proficiency_estimate TEXT NOT NULL DEFAULT 'B1',
    grammar_mistakes_json TEXT NOT NULL DEFAULT '[]',
    pronunciation_issues_json TEXT NOT NULL DEFAULT '[]',
    completed_exercises_json TEXT NOT NULL DEFAULT '[]',
    session_summaries_json TEXT NOT NULL DEFAULT '[]',
    total_speaking_seconds INTEGER NOT NULL DEFAULT 0,
    streak_days INTEGER NOT NULL DEFAULT 1,
    updated_at TEXT NOT NULL
);

CREATE TABLE IF NOT EXISTS dataset_versions (
    id TEXT PRIMARY KEY,
    dataset_name TEXT NOT NULL,
    collection_name TEXT NOT NULL,
    version TEXT NOT NULL,
    license TEXT NOT NULL,
    source_url TEXT NOT NULL,
    record_count INTEGER NOT NULL DEFAULT 0,
    checksum TEXT NOT NULL,
    ingested_at TEXT NOT NULL
);

CREATE INDEX IF NOT EXISTS idx_conversations_user ON conversations(user_id, updated_at DESC);
CREATE INDEX IF NOT EXISTS idx_messages_conv ON messages(conversation_id, created_at ASC);
CREATE INDEX IF NOT EXISTS idx_user_vocab_review ON user_vocabulary_progress(user_id, next_review_at);
