"""
Application settings store.
Stores non-sensitive user preferences and configuration.
(Secrets are strictly stored in the OS Credential Store, never here).
"""

import json
import datetime
from typing import Dict, Any, Optional
from .db import Database

DEFAULT_SETTINGS = {
    "theme": "dark",
    "refresh_interval": 30,
    "default_dir": "",
    "git_path": "",
    "github_api_url": "https://api.github.com",
    "confirm_destructive": True,
    "notifications_enabled": True,
}


class SettingsStore:
    def __init__(self, db: Database):
        self.db = db

    def _now(self) -> str:
        return datetime.datetime.now(datetime.timezone.utc).isoformat()

    def get_all(self) -> Dict[str, Any]:
        """Retrieves all settings merged with defaults."""
        res = dict(DEFAULT_SETTINGS)
        conn = self.db.get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT key, value FROM settings;")
            for row in cursor.fetchall():
                key = row["key"]
                raw_val = row["value"]
                try:
                    val = json.loads(raw_val)
                except Exception:
                    val = raw_val
                res[key] = val
            return res
        finally:
            conn.close()

    def get(self, key: str, default: Any = None) -> Any:
        conn = self.db.get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT value FROM settings WHERE key = ?;", (key,))
            row = cursor.fetchone()
            if row:
                try:
                    return json.loads(row["value"])
                except Exception:
                    return row["value"]
            return default if default is not None else DEFAULT_SETTINGS.get(key)
        finally:
            conn.close()

    def set(self, key: str, value: Any):
        serialized = json.dumps(value)
        now = self._now()
        conn = self.db.get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute(
                """
                INSERT INTO settings (key, value, updated_at)
                VALUES (?, ?, ?)
                ON CONFLICT(key) DO UPDATE SET value = excluded.value, updated_at = excluded.updated_at;
                """,
                (key, serialized, now),
            )
        finally:
            conn.close()

    def set_multiple(self, settings_dict: Dict[str, Any]):
        for k, v in settings_dict.items():
            self.set(k, v)
