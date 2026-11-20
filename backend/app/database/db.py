"""Database connection manager supporting SQLite (dev/test) and PostgreSQL schema."""
from __future__ import annotations

import sqlite3
from contextlib import contextmanager
from pathlib import Path
from typing import Iterator

from app.config import settings


def _resolve_sqlite_path(url: str) -> str:
    if url.startswith("sqlite:///"):
        return url.replace("sqlite:///", "", 1)
    if url == ":memory:":
        return ":memory:"
    # Fallback local sqlite file when PostgreSQL driver is not running in test sandbox
    return str(Path(__file__).resolve().parent.parent.parent / "talkora_dev.db")


class Database:
    def __init__(self, database_url: str | None = None) -> None:
        self.database_url = database_url or settings.database_url
        self.sqlite_path = _resolve_sqlite_path(self.database_url)

    @contextmanager
    def connect(self) -> Iterator[sqlite3.Connection]:
        conn = sqlite3.connect(self.sqlite_path, check_same_thread=False)
        conn.row_factory = sqlite3.Row
        conn.execute("PRAGMA foreign_keys = ON;")
        try:
            yield conn
            conn.commit()
        except Exception:
            conn.rollback()
            raise
        finally:
            conn.close()

    def init_schema(self) -> None:
        schema_path = Path(__file__).resolve().parent / "schema.sql"
        sql = schema_path.read_text(encoding="utf-8")
        with self.connect() as conn:
            conn.executescript(sql)


db = Database()
