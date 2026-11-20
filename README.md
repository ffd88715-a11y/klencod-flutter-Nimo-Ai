# TALKORA AI — Complete Delivery Report, Installation Guide, License Audit & Test Report

**TALKORA AI** is a complete Android-first Flutter English-learning application paired with a self-hosted Python FastAPI real-time voice conversation backend, PostgreSQL schema, Qdrant vector retrieval layer, Redis/Docker configuration, model setup CLI, and license-gated dataset ingestion pipeline.

---

## 1. Repository Structure (`talkora_ai_complete.zip`)

| Path | Contents |
| :--- | :--- |
| `flutter_app/lib/app/` | Material 3 Light/Dark design system (`#6558F5` / `#10111A`), Inter & Cairo typography, EN/AR localization with RTL/LTR `Directionality`, and GoRouter 5-tab `StatefulShellRoute` |
| `flutter_app/lib/core/` | Configurable self-hosted `ApiConfig`, Dio REST client, `VoiceSocketService` (WebSocket streaming + barge-in interruption), `MicPermissionService`, `TalkoraWaveform` & `TalkoraVoiceOrb` |
| `flutter_app/lib/features/` | Splash, Onboarding (CEFR A1–C2, 7 goals, accents), Home Dashboard, Live Voice Conversation, Practice Hub, Vocabulary SM-2 SRS, Pronunciation Coach, Grammar Studio, Listening Lab, Daily Challenge, Progress Analytics, Profile & Privacy Controls, Server Settings |
| `flutter_app/android/` | `AndroidManifest.xml` (mic, internet, audio routing, Bluetooth headset, notifications), `build.gradle` (compileSdk 35, minSdk 24, ABI splits, release minify/shrinkResources), and `proguard-rules.pro` |
| `backend/app/` | Modular FastAPI backend (`auth`, `conversations`, `voice`, `stt`, `tts`, `llm`, `vocabulary`, `pronunciation`, `learning`, `memory`, `knowledge`, `ingestion`, `database`, `models`, `services`, `security`) |
| `backend/app/database/schema.sql` | Production PostgreSQL 16 schema (users, conversations, messages, vocabulary, SM-2 progress, pronunciation/grammar attempts, learning memory, dataset versions) |
| `backend/scripts/` | `download_models.py` (self-hosted weight setup) and `ingest_datasets.py` (validation, deduplication, license enforcement, versioning) |
| `backend/Dockerfile` & `docker-compose.yml` | Production container stack: FastAPI + PostgreSQL 16 + Qdrant + Redis + self-hosted `llama.cpp` inference server |

---

## 2. Selected Self-Hosted AI Stack & Model License Report

No paid commercial AI API keys are required. Components were selected for low latency, self-hosted reliability, and clear open-source licensing:

| Pipeline Stage | Selected Component | License | Source & Compliance Notes |
| :--- | :--- | :--- | :--- |
| **Voice Activity Detection (VAD)** | Silero VAD v5 | MIT | [snakers4/silero-vad](https://github.com/snakers4/silero-vad/blob/master/LICENSE) — lightweight CPU/ONNX speech boundary detection |
| **Streaming STT** | faster-whisper (`small.en` / `medium.en`) | MIT | [SYSTRAN/faster-whisper](https://github.com/SYSTRAN/faster-whisper) — CTranslate2 int8/fp16 inference (up to 4x faster than baseline Whisper) |
| **Conversational LLM** | Qwen3-8B-Instruct via `llama.cpp` (or `vLLM` for multi-user GPU) | Apache-2.0 (model), MIT (`llama.cpp`), Apache-2.0 (`vLLM`) | [QwenLM/Qwen3](https://github.com/QwenLM/Qwen3), [ggml-org/llama.cpp](https://github.com/ggml-org/llama.cpp/blob/master/LICENSE), [vllm-project/vllm](https://github.com/vllm-project/vllm) (note optional `soxr` LGPL audio dep in [vLLM #8030](https://github.com/vllm-project/vllm/issues/8030)) |
| **Streaming TTS (Primary GPU)** | Qwen3-TTS (`12Hz-0.6B-CustomVoice`) | Apache-2.0 | [QwenLM/Qwen3-TTS](https://github.com/QwenLM/Qwen3-TTS) — dual-track streaming speech synthesis (as low as 97ms first-packet latency) |
| **Streaming TTS (Lightweight CPU/GPU)** | Kokoro-82M (optional alternative) | Apache-2.0 weights; **GPL-3.0 fallback notice** | [hexgrad/kokoro](https://github.com/hexgrad/kokoro/blob/main/LICENSE) — weights are Apache-2.0, but Python `misaki[en]` pulls in `espeak-ng` (GPL-3.0) for out-of-dictionary fallback ([Issue #247](https://github.com/hexgrad/kokoro/issues/247)); isolate as a separate service or provide GPL notices if enabled |
| **Orchestration Reference** | Modular FastAPI WebSocket (compatible with Pipecat / LiveKit / sherpa-onnx) | BSD-2-Clause / Apache-2.0 | [pipecat-ai/pipecat](https://github.com/pipecat-ai/pipecat/blob/main/LICENSE), [livekit/agents](https://github.com/livekit/agents/blob/main/LICENSE) (note separate [Model License](https://github.com/livekit/agents/blob/main/MODEL_LICENSE)), [k2-fsa/sherpa-onnx](https://github.com/k2-fsa/sherpa-onnx), [huggingface/speech-to-speech](https://github.com/huggingface/speech-to-speech) |

---

## 3. Educational Dataset License Report

Dataset ingestion is strictly license-gated in `backend/app/ingestion/pipeline.py` and `backend/datasets/manifest.json`:

| Dataset | Target Collection | Verified License | Redistributable | Source URL |
| :--- | :--- | :--- | :--- | :--- |
| Mozilla Common Voice (EN) | `listening_materials` | CC0-1.0 (Public Domain) | Yes | [commonvoice.mozilla.org](https://commonvoice.mozilla.org/) |
| Google FLEURS (EN/AR) | `listening_materials` | CC-BY-4.0 | Yes (attribution) | [google/fleurs](https://huggingface.co/datasets/google/fleurs) ([License confirmation](https://huggingface.co/datasets/google/fleurs/discussions/2)) |
| SpeechOcean762 (OpenSLR 101) | `pronunciation` | CC-BY-4.0 | Yes (attribution) | [openslr.org/101](https://www.openslr.org/101/) |
| LibriSpeech (OpenSLR 12) | `listening_materials` | CC-BY-4.0 | Yes (attribution) | [openslr.org/12](https://www.openslr.org/12) |
| Tatoeba (EN-AR) | `arabic_english_explanations` | CC-BY-2.0-FR / CC0-1.0 | Yes (attribution) | [tatoeba.org/en/downloads](https://tatoeba.org/en/downloads) |
| VoxPopuli (L2 Accented EN) | `pronunciation` | CC0-1.0 | Yes | [facebookresearch/voxpopuli](https://github.com/facebookresearch/voxpopuli/blob/main/LICENSE) |
| OPUS Parallel Corpora (filtered) | `dialogue_examples` | Per-corpus (CC0 / CC-BY-SA-4.0; NC excluded) | Filtered only | [opus.nlpl.eu](https://opus.nlpl.eu/) |
| JFLEG (GEC Corpus) | `grammar` (benchmarking only) | Research/Academic — Verify | **Excluded by default** | [keisks/jfleg](https://github.com/keisks/jfleg) |

---

## 4. Installation & APK Build Guide

### A. Self-Hosted Backend (Docker — Recommended)
```bash
unzip talkora_ai_complete.zip
cd talkora_ai/backend

# 1. Download self-hosted model weights (GPU profile uses Qwen3-TTS; use --profile cpu for Kokoro)
python3 scripts/download_models.py --profile gpu --models-dir ./models

# 2. Launch PostgreSQL, Qdrant, Redis, FastAPI, and llama.cpp LLM server
docker compose --profile ai-gpu up -d --build

# 3. Run license-validated dataset ingestion
python3 scripts/ingest_datasets.py --sample-seed

# 4. Verify backend health
curl http://localhost:8000/health
```

### B. Flutter Android App & Release APK Build
```bash
cd talkora_ai/flutter_app
flutter pub get
flutter analyze
flutter test

# Build production split-per-ABI Android APKs (arm64-v8a + armeabi-v7a + universal)
flutter build apk --release --split-per-abi
```
To connect a physical Android device on your LAN, open **Profile → Settings** inside the app and set the Backend Server URL to `http://<YOUR_SERVER_LAN_IP>:8000`.

---

## 5. Automated Test & Validation Report

| Check | Environment | Result | Notes |
| :--- | :--- | :--- | :--- |
| Backend Auth, JWT, Profile Update (`test_01`) | Executed in Sandbox (Python 3.11 + FastAPI TestClient) | **PASS** | Verified registration, PBKDF2 password login, JWT auth, and CEFR profile patch |
| Conversations, Grammar Correction & AI Identity (`test_02`) | Executed in Sandbox | **PASS** | Verified grammar mistake detection (`didn't went` → `didn't go`), Arabic gloss, and explicit AI self-identification |
| Live WebSocket Voice Pipeline + Barge-In Interruption (`test_03`) | Executed in Sandbox | **PASS** | Verified PCM16 VAD RMS detection, transcript, LLM reply, streaming WAV TTS chunks, and immediate `interrupt` playback stop |
| Vocabulary SM-2 SRS, Pronunciation, Grammar, Listening, Daily Challenge, Progress (`test_04`) | Executed in Sandbox | **PASS** | Verified SM-2 interval update, phoneme mistake detection, 100% quiz grading, fluency scoring, and analytics |
| AI Memory Privacy, Export, Reset & License-Gated Ingestion (`test_05`) | Executed in Sandbox | **PASS** | Verified JSON export, privacy toggles, deduplication, and rejection of non-allowlisted licenses (`PROPRIETARY-RESTRICTED`) |
| Model Setup CLI (`download_models.py --dry-run`) & Dataset CLI (`ingest_datasets.py --sample-seed`) | Executed in Sandbox | **PASS** | Verified 7 approved datasets ingested with SHA-256 checksums and `jfleg_gec` automatically skipped |
| Flutter Static Structural Audit (Dart files + Manifest + Gradle) | Executed in Sandbox | **PASS** | Verified balanced braces/parens, zero dynamic `IconData()` calls (safe for release tree-shaking), RTL `Directionality`, and Android permissions |
| `flutter analyze`, `flutter test`, `flutter build apk --release` & Physical Android Device Tests | **Pending Local Flutter SDK** | **NOT RUN IN SANDBOX** | Flutter/Android SDK is not installed in this Linux sandbox VM; run on your local workstation and physical Android device (mic, Bluetooth headset, background audio, reconnect) before production release |
