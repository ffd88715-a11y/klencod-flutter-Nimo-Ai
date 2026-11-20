"""End-to-end automated test suite for TALKORA AI Backend."""
from __future__ import annotations

import base64
import math
import os
import struct
import tempfile
import unittest
from pathlib import Path
import sys

# Configure isolated temporary SQLite database before importing app
_tmp = tempfile.NamedTemporaryFile(suffix=".db", delete=False)
_tmp.close()
os.environ["DATABASE_URL"] = f"sqlite:///{_tmp.name}"
os.environ["TALKORA_LLM_PROVIDER"] = "local_hybrid"

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from fastapi.testclient import TestClient  # noqa: E402
from app.main import app  # noqa: E402
from app.ingestion.pipeline import ingest_collection  # noqa: E402


class TalkoraBackendTestSuite(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls.client = TestClient(app)
        from app.main import bootstrap_application
        bootstrap_application()
        reg = cls.client.post(
            "/api/v1/auth/register",
            json={
                "email": "learner@talkora.ai",
                "password": "StrongPassword123",
                "display_name": "Yossef",
                "native_language": "Arabic",
                "english_level": "B1",
                "learning_goal": "Fluency",
                "preferred_accent": "American",
                "daily_target_minutes": 20,
                "explanation_language": "Arabic",
            },
        )
        assert reg.status_code == 201, reg.text
        cls.token = reg.json()["access_token"]
        cls.headers = {"Authorization": f"Bearer {cls.token}"}

    @classmethod
    def tearDownClass(cls) -> None:
        Path(_tmp.name).unlink(missing_ok=True)

    def test_01_health_and_auth_login_profile(self) -> None:
        h = self.client.get("/health")
        self.assertEqual(h.status_code, 200)
        self.assertEqual(h.json()["status"], "ok")

        login = self.client.post(
            "/api/v1/auth/login",
            json={"email": "learner@talkora.ai", "password": "StrongPassword123"},
        )
        self.assertEqual(login.status_code, 200)
        self.assertIn("access_token", login.json())

        upd = self.client.patch(
            "/api/v1/auth/profile",
            headers=self.headers,
            json={"english_level": "B2", "daily_target_minutes": 25},
        )
        self.assertEqual(upd.status_code, 200)
        self.assertEqual(upd.json()["english_level"], "B2")

    def test_02_conversation_grammar_correction_and_ai_identity(self) -> None:
        conv = self.client.post(
            "/api/v1/conversations",
            headers=self.headers,
            json={"title": "Flutter & Career", "mode": "free_conversation", "topic": "Programming"},
        )
        self.assertEqual(conv.status_code, 201)
        conv_id = conv.json()["id"]

        turn1 = self.client.post(
            f"/api/v1/conversations/{conv_id}/turn",
            headers=self.headers,
            json={"message": "Yesterday I didn't went to the office because I was coding Flutter."},
        )
        self.assertEqual(turn1.status_code, 200)
        data = turn1.json()
        self.assertTrue(data["correction"]["has_issue"])
        self.assertIn("didn't go", data["correction"]["corrected"].lower())
        self.assertTrue(len(data["arabic_translation"]) > 0)

        turn2 = self.client.post(
            f"/api/v1/conversations/{conv_id}/turn",
            headers=self.headers,
            json={"message": "Wait, are you a real person?"},
        )
        self.assertEqual(turn2.status_code, 200)
        self.assertIn("AI", turn2.json()["assistant_reply"])

    def test_03_realtime_websocket_voice_streaming_and_interruption(self) -> None:
        # Generate a 200ms 440Hz PCM16 speech-like tone frame so VAD triggers speech=True
        samples = [int(12000 * math.sin(2 * math.pi * 440 * i / 16000)) for i in range(3200)]
        pcm_bytes = struct.pack(f"<{len(samples)}h", *samples)
        b64_pcm = base64.b64encode(pcm_bytes).decode("ascii")

        with self.client.websocket_connect("/ws/voice/test-sess-1?display_name=Yossef&cefr_level=B2") as ws:
            init_state = ws.receive_json()
            self.assertEqual(init_state["state"], "listening")

            ws.send_json({"type": "audio_chunk", "audio_base64": b64_pcm})
            vad_msg = ws.receive_json()
            self.assertEqual(vad_msg["type"], "vad")
            self.assertTrue(vad_msg["is_speech"])
            self.assertGreater(vad_msg["rms_level"], 0.1)

            ws.send_json({"type": "end_of_speech", "transcript_override": "I love traveling and learning English."})
            events = []
            for _ in range(12):
                evt = ws.receive_json()
                events.append(evt)
                if evt.get("type") == "state" and evt.get("state") == "listening":
                    break

            event_types = [e["type"] for e in events]
            self.assertIn("transcript", event_types)
            self.assertIn("assistant_text", event_types)
            self.assertIn("tts_chunk", event_types)
            self.assertIn("turn_complete", event_types)

            # Test barge-in interruption
            ws.send_json({"type": "interrupt"})
            int_msg = ws.receive_json()
            self.assertEqual(int_msg["state"], "interrupted")
            self.assertTrue(int_msg["stop_playback"])
            back_to_listen = ws.receive_json()
            self.assertEqual(back_to_listen["state"], "listening")

    def test_04_vocabulary_srs_pronunciation_grammar_listening_challenge(self) -> None:
        vocab = self.client.get("/api/v1/vocabulary", headers=self.headers)
        self.assertEqual(vocab.status_code, 200)
        self.assertGreaterEqual(len(vocab.json()), 10)

        rev = self.client.post("/api/v1/vocabulary/voc_001/review", headers=self.headers, json={"quality": 5})
        self.assertEqual(rev.status_code, 200)
        self.assertEqual(rev.json()["repetitions"], 1)

        fav = self.client.post("/api/v1/vocabulary/voc_001/favorite", headers=self.headers, json={"is_favorite": True})
        self.assertEqual(fav.status_code, 200)
        self.assertTrue(fav.json()["is_favorite"])

        pron = self.client.post(
            "/api/v1/pronunciation/evaluate",
            headers=self.headers,
            json={"target_text": "practice very clear pronunciation", "spoken_text": "bractice fery clear pronunciation"},
        )
        self.assertEqual(pron.status_code, 200)
        self.assertGreater(len(pron.json()["phoneme_mistakes"]), 0)

        gram = self.client.post(
            "/api/v1/learning/grammar/submit",
            headers=self.headers,
            json={"lesson_id": "gram_001", "answers": {"q1": "has lived", "q2": "visited"}},
        )
        self.assertEqual(gram.status_code, 200)
        self.assertEqual(gram.json()["score"], 100.0)

        listening = self.client.get("/api/v1/learning/listening")
        self.assertEqual(listening.status_code, 200)
        self.assertGreaterEqual(len(listening.json()), 2)

        chal = self.client.get("/api/v1/learning/daily-challenge")
        self.assertEqual(chal.status_code, 200)
        chal_sub = self.client.post(
            "/api/v1/learning/daily-challenge/submit",
            headers=self.headers,
            json={
                "challenge_id": chal.json()["id"],
                "transcript": "First I wake up early, drink coffee, and after that I practice speaking English for twenty minutes.",
                "duration_seconds": 45,
            },
        )
        self.assertEqual(chal_sub.status_code, 200)
        self.assertGreater(chal_sub.json()["fluency_score"], 60.0)

        prog = self.client.get("/api/v1/learning/progress", headers=self.headers)
        self.assertEqual(prog.status_code, 200)
        self.assertGreaterEqual(prog.json()["vocabulary_learned"], 1)

    def test_05_memory_privacy_export_and_dataset_ingestion(self) -> None:
        exp = self.client.get("/api/v1/memory/export", headers=self.headers)
        self.assertEqual(exp.status_code, 200)
        self.assertIn("conversations", exp.json())

        priv = self.client.patch(
            "/api/v1/memory/privacy",
            headers=self.headers,
            json={"memory_enabled": False, "store_recordings": False},
        )
        self.assertEqual(priv.status_code, 200)
        self.assertFalse(priv.json()["memory_enabled"])

        # Test dataset ingestion deduplication + license rejection
        res = ingest_collection(
            dataset_name="tatoeba_en_ar",
            collection_name="everyday_expressions",
            version="2026.11",
            license_id="CC-BY-2.0-FR",
            source_url="https://tatoeba.org/en/downloads",
            records=[
                {"text": "How is your day going?"},
                {"text": "how is your day going?"},  # duplicate
                {"text": " "},  # invalid
            ],
        )
        self.assertEqual(res["stats"]["accepted"], 1)
        self.assertEqual(res["stats"]["skipped_duplicates"], 1)
        self.assertEqual(res["stats"]["skipped_invalid"], 1)

        with self.assertRaises(ValueError):
            ingest_collection(
                dataset_name="unlicensed_test",
                collection_name="grammar",
                version="1.0",
                license_id="PROPRIETARY-RESTRICTED",
                source_url="https://example.com",
                records=[{"text": "Test"}],
            )

        reset = self.client.post("/api/v1/memory/reset", headers=self.headers)
        self.assertEqual(reset.status_code, 200)
        self.assertEqual(reset.json()["status"], "reset_complete")


if __name__ == "__main__":
    unittest.main(verbosity=2)
