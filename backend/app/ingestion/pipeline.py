"""Dataset ingestion pipeline with validation, deduplication, license tracking, and versioning."""
from __future__ import annotations

import hashlib
import json
import uuid
from datetime import datetime, timezone
from typing import Any

from app.database.db import db
from app.knowledge.vector_store import COLLECTIONS, vector_store

APPROVED_LICENSES = {
    "CC0-1.0",
    "CC-BY-4.0",
    "CC-BY-2.0-FR",
    "CC-BY-SA-4.0",
    "MIT",
    "Apache-2.0",
    "BSD-2-Clause",
}


def validate_and_deduplicate(records: list[dict[str, Any]], license_id: str) -> tuple[list[dict[str, Any]], dict[str, int]]:
    if license_id not in APPROVED_LICENSES:
        raise ValueError(f"License '{license_id}' is not in the approved redistributable license allowlist.")

    seen_hashes: set[str] = set()
    clean: list[dict[str, Any]] = []
    skipped_invalid = 0
    skipped_duplicates = 0

    for rec in records:
        text = str(rec.get("text", "")).strip()
        if len(text) < 2:
            skipped_invalid += 1
            continue
        norm_hash = hashlib.sha256(text.lower().encode("utf-8")).hexdigest()
        if norm_hash in seen_hashes:
            skipped_duplicates += 1
            continue
        seen_hashes.add(norm_hash)
        clean.append({**rec, "text": text, "content_hash": norm_hash, "license": license_id})

    return clean, {
        "accepted": len(clean),
        "skipped_invalid": skipped_invalid,
        "skipped_duplicates": skipped_duplicates,
    }


def ingest_collection(
    dataset_name: str,
    collection_name: str,
    version: str,
    license_id: str,
    source_url: str,
    records: list[dict[str, Any]],
) -> dict[str, Any]:
    if collection_name not in COLLECTIONS:
        raise ValueError(f"Unknown collection '{collection_name}'. Valid collections: {COLLECTIONS}")

    clean_records, stats = validate_and_deduplicate(records, license_id)
    indexed = vector_store.upsert(collection_name, clean_records)

    payload_digest = hashlib.sha256(
        json.dumps([r["content_hash"] for r in clean_records], sort_keys=True).encode("utf-8")
    ).hexdigest()[:16]

    now = datetime.now(timezone.utc).isoformat()
    version_id = str(uuid.uuid4())
    with db.connect() as conn:
        conn.execute(
            """
            INSERT INTO dataset_versions
            (id, dataset_name, collection_name, version, license, source_url, record_count, checksum, ingested_at)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
            """,
            (version_id, dataset_name, collection_name, version, license_id, source_url, indexed, payload_digest, now),
        )

    return {
        "version_id": version_id,
        "dataset_name": dataset_name,
        "collection_name": collection_name,
        "version": version,
        "license": license_id,
        "source_url": source_url,
        "checksum": payload_digest,
        "stats": stats,
    }
