#!/usr/bin/env python3
"""Downloads and verifies locally managed open-source model weights for TALKORA AI."""
from __future__ import annotations

import argparse
from pathlib import Path

MODEL_REGISTRY = {
    "vad": {
        "name": "Silero VAD v5",
        "repo": "snakers4/silero-vad",
        "license": "MIT",
        "url": "https://github.com/snakers4/silero-vad",
    },
    "stt": {
        "name": "faster-whisper small.en (CTranslate2)",
        "repo": "Systran/faster-whisper-small.en",
        "license": "MIT",
        "url": "https://github.com/SYSTRAN/faster-whisper",
    },
    "llm": {
        "name": "Qwen3-8B-Instruct (GGUF Q4_K_M for llama.cpp)",
        "repo": "Qwen/Qwen3-8B-GGUF",
        "license": "Apache-2.0",
        "url": "https://github.com/QwenLM/Qwen3",
    },
    "tts_gpu": {
        "name": "Qwen3-TTS-12Hz-0.6B-CustomVoice",
        "repo": "Qwen/Qwen3-TTS-12Hz-0.6B-CustomVoice",
        "license": "Apache-2.0",
        "url": "https://github.com/QwenLM/Qwen3-TTS",
    },
    "tts_cpu": {
        "name": "Kokoro-82M (Apache-2.0 weights; note GPL-3.0 espeak-ng fallback)",
        "repo": "hexgrad/Kokoro-82M",
        "license": "Apache-2.0",
        "url": "https://github.com/hexgrad/kokoro",
    },
}


def main() -> None:
    parser = argparse.ArgumentParser(description="TALKORA AI self-hosted model weight downloader")
    parser.add_argument("--models-dir", default="./models", help="Local directory for model weights")
    parser.add_argument("--dry-run", action="store_true", help="Print selected models and licenses without downloading")
    parser.add_argument("--profile", choices=["cpu", "gpu"], default="gpu", help="Target hardware profile")
    args = parser.parse_args()

    target = Path(args.models_dir)
    selected = ["vad", "stt", "llm", "tts_gpu" if args.profile == "gpu" else "tts_cpu"]
    print(f"TALKORA AI Model Setup (profile={args.profile}, dir={target.resolve()})")
    for key in selected:
        info = MODEL_REGISTRY[key]
        print(f"  - [{key.upper()}] {info['name']} | License: {info['license']} | Repo: {info['repo']}")

    if args.dry_run:
        print("Dry run complete. No files downloaded.")
        return

    from huggingface_hub import snapshot_download  # type: ignore

    target.mkdir(parents=True, exist_ok=True)
    for key in selected:
        if key == "vad":
            continue  # Silero VAD loads via torch.hub or onnx directly
        info = MODEL_REGISTRY[key]
        dest = target / key
        print(f"Downloading {info['repo']} -> {dest} ...")
        snapshot_download(repo_id=info["repo"], local_dir=str(dest))
    print("All selected model weights downloaded successfully.")


if __name__ == "__main__":
    main()
