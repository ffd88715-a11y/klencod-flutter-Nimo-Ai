#!/usr/bin/env python3
"""Resumable dataset ingestion CLI for TALKORA AI Qdrant knowledge collections."""
from __future__ import annotations

import argparse
import json
from pathlib import Path
import sys

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.database.db import db
from app.ingestion.pipeline import APPROVED_LICENSES, ingest_collection


def main() -> None:
    parser = argparse.ArgumentParser(description="Ingest validated open-licensed datasets into TALKORA AI")
    parser.add_argument("--manifest", default=str(Path(__file__).resolve().parent.parent / "datasets/manifest.json"))
    parser.add_argument("--sample-seed", action="store_true", help="Run offline validation & indexing with sample records")
    args = parser.parse_args()

    manifest = json.loads(Path(args.manifest).read_text(encoding="utf-8"))
    db.init_schema()

    for entry in manifest["datasets"]:
        lic = entry["license"]
        if not entry.get("redistributable") or lic not in APPROVED_LICENSES:
            print(f"[SKIP] {entry['name']} — license '{lic}' requires manual review / non-redistributable.")
            continue
        if args.sample_seed:
            sample_records = [
                {"text": f"Sample validated entry for {entry['name']}", "source": entry["source_url"], "cefr": "B1"},
                {"text": f"Sample validated entry for {entry['name']}", "source": entry["source_url"], "cefr": "B1"},
            ]
            res = ingest_collection(
                dataset_name=entry["name"],
                collection_name=entry["collection"],
                version="1.0.0",
                license_id=lic,
                source_url=entry["source_url"],
                records=sample_records,
            )
            print(f"[OK] {entry['name']} -> {entry['collection']} | stats={res['stats']} | checksum={res['checksum']}")


if __name__ == "__main__":
    main()
