"""WebSocket real-time voice conversation pipeline: MIC -> VAD -> STT -> LLM -> Streaming TTS."""
from __future__ import annotations

import base64
import uuid

from fastapi import APIRouter, WebSocket, WebSocketDisconnect

from app.models.schemas import model_to_dict
from app.llm.engine import llm_engine
from app.stt.engine import stt_engine, vad_engine
from app.tts.engine import tts_engine
from app.voice.pipeline import VoiceSessionState

router = APIRouter(tags=["Voice Streaming"])


@router.websocket("/ws/voice/{session_id}")
async def voice_stream_endpoint(websocket: WebSocket, session_id: str) -> None:
    await websocket.accept()
    user_id = websocket.query_params.get("user_id", "guest")
    cefr_level = websocket.query_params.get("cefr_level", "B1")
    display_name = websocket.query_params.get("display_name", "Learner")
    accent = websocket.query_params.get("accent", "American")
    mode = websocket.query_params.get("mode", "free_conversation")

    session = VoiceSessionState(session_id=session_id or str(uuid.uuid4()), user_id=user_id, mode=mode)
    session.state = "listening"
    await websocket.send_json({"type": "state", "state": "listening", "session_id": session.session_id})

    profile = {
        "display_name": display_name,
        "english_level": cefr_level,
        "preferred_accent": accent,
        "learning_goal": "Fluency",
    }

    try:
        while True:
            msg = await websocket.receive_json()
            msg_type = msg.get("type", "")

            if msg_type == "ping":
                await websocket.send_json({"type": "pong"})
                continue

            if msg_type == "mute":
                session.is_muted = bool(msg.get("muted", True))
                await websocket.send_json({"type": "mute_ack", "muted": session.is_muted})
                continue

            if msg_type == "interrupt":
                new_turn = session.interrupt()
                await websocket.send_json(
                    {"type": "state", "state": "interrupted", "turn_id": new_turn, "stop_playback": True}
                )
                session.state = "listening"
                await websocket.send_json({"type": "state", "state": "listening", "turn_id": new_turn})
                continue

            if msg_type == "audio_chunk":
                if session.is_muted:
                    continue
                pcm = base64.b64decode(msg.get("audio_base64", "")) if msg.get("audio_base64") else b""
                vad_res = vad_engine.analyze_pcm16(pcm)
                if vad_res.is_speech:
                    session.audio_buffer.extend(pcm)
                await websocket.send_json(
                    {
                        "type": "vad",
                        "is_speech": vad_res.is_speech,
                        "rms_level": vad_res.rms_level,
                        "speech_probability": vad_res.speech_probability,
                    }
                )
                continue

            if msg_type == "end_of_speech":
                active_turn = session.begin_new_turn()
                session.state = "understanding"
                await websocket.send_json({"type": "state", "state": "understanding", "turn_id": active_turn})

                transcript = stt_engine.transcribe_pcm16(
                    bytes(session.audio_buffer),
                    hint_text=msg.get("transcript_override"),
                )
                session.audio_buffer.clear()

                await websocket.send_json(
                    {"type": "transcript", "role": "user", "text": transcript, "turn_id": active_turn}
                )

                session.state = "thinking"
                await websocket.send_json({"type": "state", "state": "thinking", "turn_id": active_turn})

                llm_out = await llm_engine.generate_reply(
                    user_text=transcript,
                    history=session.history,
                    profile=profile,
                    topic=msg.get("topic", "Daily Life"),
                )
                if session.cancel_event.is_set() or active_turn != session.turn_id:
                    continue

                session.history.append({"role": "user", "content": transcript})
                session.history.append({"role": "assistant", "content": llm_out["reply"]})

                correction = llm_out["correction"]
                await websocket.send_json(
                    {
                        "type": "assistant_text",
                        "turn_id": active_turn,
                        "text": llm_out["reply"],
                        "arabic_translation": llm_out["arabic_translation"],
                        "correction": model_to_dict(correction) if correction else None,
                    }
                )

                session.state = "speaking"
                await websocket.send_json({"type": "state", "state": "speaking", "turn_id": active_turn})

                for chunk in tts_engine.stream_audio_chunks(llm_out["reply"], accent=accent):
                    if session.cancel_event.is_set() or active_turn != session.turn_id:
                        break
                    await websocket.send_json({"type": "tts_chunk", "turn_id": active_turn, **chunk})

                if not session.cancel_event.is_set() and active_turn == session.turn_id:
                    session.state = "listening"
                    await websocket.send_json({"type": "turn_complete", "turn_id": active_turn})
                    await websocket.send_json({"type": "state", "state": "listening", "turn_id": active_turn})

    except WebSocketDisconnect:
        session.interrupt()
