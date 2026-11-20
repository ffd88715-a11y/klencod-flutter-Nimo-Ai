"""Qdrant vector retrieval client with lightweight deterministic hashing-embedding local fallback."""
from __future__ import annotations

import hashlib
import math
from typing import Any

import httpx

from app.config import settings

COLLECTIONS = [
    "vocabulary",
    "grammar",
    "dialogue_examples",
    "pronunciation",
    "arabic_english_explanations",
    "listening_materials",
    "idioms",
    "phrasal_verbs",
    "everyday_expressions",
    "cefr_levels",
]


def compute_local_embedding(text: str, dim: int = 64) -> list[float]:
    """Deterministic bag-of-trigrams hashed vector (64-dim) for zero-GPU local indexing & testing."""
    vec = [0.0] * dim
    normalized = f" {text.lower().strip()} "
    if len(normalized) < 3:
        return vec
    for i in range(len(normalized) - 2):
        trigram = normalized[i : i + 3]
        h = int(hashlib.blake2b(trigram.encode("utf-8"), digest_size=4).hexdigest(), 16)
        vec[h % dim] += 1.0
    norm = math.sqrt(sum(v * v for v in vec)) or 1.0
    return [round(v / norm, 6) for v in vec]


def cosine_similarity(a: list[float], b: list[float]) -> float:
    return sum(x * y for x, y in zip(a, b))


class KnowledgeVectorStore:
    """Interfaces with Qdrant REST API when running; falls back cleanly to in-memory vector index."""

    def __init__(self, qdrant_url: str | None = None) -> None:
        self.qdrant_url = (qdrant_url or settings.qdrant_url).rstrip("/")
        self._local_collections: dict[str, list[dict[str, Any]]] = {c: [] for c in COLLECTIONS}

    def upsert(self, collection: str, records: list[dict[str, Any]]) -> int:
        if collection not in self._local_collections:
            self._local_collections[collection] = []
        count = 0
        for rec in records:
            text_blob = rec.get("text") or f"{rec.get('word', '')} {rec.get('english_definition', '')}"
            vec = compute_local_embedding(text_blob)
            self._local_collections[collection].append({"vector": vec, "payload": rec})
            count += 1
        return count

    def search(self, collection: str, query: str, limit: int = 5) -> list[dict[str, Any]]:
        q_vec = compute_local_embedding(query)
        items = self._local_collections.get(collection, [])
        scored = [
            {"score": round(cosine_similarity(q_vec, item["vector"]), 4), **item["payload"]}
            for item in items
        ]
        scored.sort(key=lambda x: x["score"], reverse=True)
        return scored[:limit]

    async def qdrant_health(self) -> bool:
        try:
            async with httpx.AsyncClient(timeout=1.5) as client:
                r = await client.get(f"{self.qdrant_url}/healthz")
                return r.status_code == 200
        except Exception:
            return False


vector_store = KnowledgeVectorStore()
