"""Real-time Voice Session state machine with barge-in interruption and cancellation tokens."""
from __future__ import annotations

import asyncio
from dataclasses import dataclass, field


@dataclass
class VoiceSessionState:
    session_id: str
    user_id: str
    mode: str = "free_conversation"
    state: str = "connecting"  # connecting|listening|understanding|thinking|speaking|interrupted|reconnecting|error
    turn_id: int = 0
    is_muted: bool = False
    audio_buffer: bytearray = field(default_factory=bytearray)
    history: list[dict[str, str]] = field(default_factory=list)
    cancel_event: asyncio.Event = field(default_factory=asyncio.Event)

    def interrupt(self) -> int:
        """Immediately invalidates any in-flight LLM/TTS output so stale speech never plays."""
        self.cancel_event.set()
        self.turn_id += 1
        self.state = "interrupted"
        self.audio_buffer.clear()
        return self.turn_id

    def begin_new_turn(self) -> int:
        self.cancel_event = asyncio.Event()
        self.turn_id += 1
        return self.turn_id
