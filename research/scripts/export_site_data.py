#!/usr/bin/env python3
"""Export the canonical research database for Evidence to ingest at build time."""

from __future__ import annotations

import sqlite3
import tempfile
from pathlib import Path


RESEARCH_ROOT = Path(__file__).resolve().parents[1]
REPOSITORY_ROOT = RESEARCH_ROOT.parent
SOURCE_DATABASE = RESEARCH_ROOT / "data" / "arcane_odyssey_cooking.sqlite"
SITE_DATABASE = (
    REPOSITORY_ROOT
    / "site"
    / "sources"
    / "arcane_index"
    / "arcane_odyssey_cooking.sqlite"
)


def integrity_check(connection: sqlite3.Connection, label: str) -> None:
    result = connection.execute("PRAGMA integrity_check").fetchone()
    if result is None or result[0] != "ok":
        detail = result[0] if result else "no result"
        raise RuntimeError(f"{label} database failed integrity_check: {detail}")


def export_database(source: Path = SOURCE_DATABASE, target: Path = SITE_DATABASE) -> None:
    if not source.is_file():
        raise FileNotFoundError(f"canonical database does not exist: {source}")

    target.parent.mkdir(parents=True, exist_ok=True)
    temporary_path: Path | None = None
    try:
        with tempfile.NamedTemporaryFile(
            prefix=f".{target.stem}-",
            suffix=target.suffix,
            dir=target.parent,
            delete=False,
        ) as temporary:
            temporary_path = Path(temporary.name)

        source_uri = f"{source.resolve().as_uri()}?mode=ro"
        with sqlite3.connect(source_uri, uri=True) as source_connection:
            integrity_check(source_connection, "canonical")
            with sqlite3.connect(temporary_path) as target_connection:
                source_connection.backup(target_connection)
                integrity_check(target_connection, "exported")

        temporary_path.replace(target)
    except Exception:
        if temporary_path is not None:
            temporary_path.unlink(missing_ok=True)
        raise

    print(f"Exported {source} -> {target}")


if __name__ == "__main__":
    export_database()
