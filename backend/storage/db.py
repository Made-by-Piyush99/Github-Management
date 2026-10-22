"""
Database connection manager with WAL mode, transactions, and safe migrations.
"""

import os
import sqlite3
import logging
from typing import Optional
from .schema import apply_migrations

logger = logging.getLogger("DevSync.Storage.DB")


def get_default_db_path() -> str:
    app_data = os.environ.get("APPDATA")
    if app_data:
        base_dir = os.path.join(app_data, "DevSyncStudio")
    else:
        base_dir = os.path.expanduser("~/.devsync_studio")
    os.makedirs(base_dir, exist_ok=True)
    return os.path.join(base_dir, "devsync.db")


class Database:
    def __init__(self, db_path: Optional[str] = None):
        self.db_path = db_path or get_default_db_path()
        self._init_db()

    def get_connection(self) -> sqlite3.Connection:
        """Returns a configured SQLite connection."""
        conn = sqlite3.connect(
            self.db_path,
            timeout=30.0,
            check_same_thread=False,
            isolation_level=None,  # Autocommit mode, explicit transactions when needed
        )
        conn.row_factory = sqlite3.Row
        cursor = conn.cursor()
        cursor.execute("PRAGMA foreign_keys = ON;")
        if self.db_path != ":memory:":
            cursor.execute("PRAGMA journal_mode = WAL;")
            cursor.execute("PRAGMA synchronous = NORMAL;")
        return conn

    def _init_db(self):
        """Initializes database schema and runs migrations."""
        if self.db_path != ":memory:":
            os.makedirs(os.path.dirname(os.path.abspath(self.db_path)), exist_ok=True)
        conn = self.get_connection()
        try:
            apply_migrations(conn)
        finally:
            conn.close()
