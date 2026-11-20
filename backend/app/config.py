"""Application configuration loaded from environment variables."""
from __future__ import annotations

import os
from dataclasses import dataclass, field
from pathlib import Path


@dataclass
class Settings:
    app_name: str = "TALKORA AI Backend"
    version: str = "1.0.0"
    environment: str = os.getenv("TALKORA_ENV", "development")
    secret_key: str = os.getenv("TALKORA_SECRET_KEY", "talkora-dev-secret-change-in-production-32bytes")
    access_token_expire_minutes: int = int(os.getenv("TALKORA_TOKEN_EXPIRE_MIN", "1440"))

    # Database: SQLite for local dev/testing, PostgreSQL for production Docker stack
    database_url: str = os.getenv(
        "DATABASE_URL",
        f"sqlite:///{Path(__file__).resolve().parent.parent / 'talkora_dev.db'}",
    )
    redis_url: str = os.getenv("REDIS_URL", "redis://localhost:6379/0")
    qdrant_url: str = os.getenv("QDRANT_URL", "http://localhost:6333")

    # Self-hosted AI endpoints (no paid commercial API keys required)
    llm_provider: str = os.getenv("TALKORA_LLM_PROVIDER", "local_hybrid")  # llama_cpp | vllm | local_hybrid
    llm_base_url: str = os.getenv("TALKORA_LLM_URL", "http://localhost:8080/v1")
    llm_model: str = os.getenv("TALKORA_LLM_MODEL", "Qwen3-8B-Instruct-Q4_K_M")

    stt_provider: str = os.getenv("TALKORA_STT_PROVIDER", "faster_whisper")  # faster_whisper | sherpa_onnx | fallback
    stt_model_size: str = os.getenv("TALKORA_STT_MODEL", "small.en")
    stt_device: str = os.getenv("TALKORA_STT_DEVICE", "cpu")

    tts_provider: str = os.getenv("TALKORA_TTS_PROVIDER", "qwen3_tts")  # qwen3_tts | kokoro | pcm_synth
    tts_voice: str = os.getenv("TALKORA_TTS_VOICE", "en_us_aria")
    tts_sample_rate: int = int(os.getenv("TALKORA_TTS_SAMPLE_RATE", "24000"))

    # Voice pipeline & safety
    vad_energy_threshold: float = float(os.getenv("TALKORA_VAD_THRESHOLD", "0.018"))
    vad_silence_ms: int = int(os.getenv("TALKORA_VAD_SILENCE_MS", "700"))
    rate_limit_requests: int = int(os.getenv("TALKORA_RATE_LIMIT_REQ", "180"))
    rate_limit_window_sec: int = int(os.getenv("TALKORA_RATE_LIMIT_WIN", "60"))
    max_audio_upload_bytes: int = 10 * 1024 * 1024  # 10 MB
    cors_origins: list[str] = field(default_factory=lambda: ["*"])


settings = Settings()
