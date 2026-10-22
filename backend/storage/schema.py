"""
SQLite schema definitions and migrations engine.
"""

import sqlite3
import logging

logger = logging.getLogger("DevSync.Storage.Schema")

MIGRATIONS = [
    # Version 1: Initial schema
    """
    CREATE TABLE IF NOT EXISTS schema_version (
        version INTEGER PRIMARY KEY
    );

    CREATE TABLE IF NOT EXISTS projects (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        local_path TEXT UNIQUE NOT NULL,
        git_remote TEXT,
        default_branch TEXT DEFAULT 'main',
        is_pinned INTEGER DEFAULT 0,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
    );

    CREATE INDEX IF NOT EXISTS idx_projects_local_path ON projects(local_path);
    CREATE INDEX IF NOT EXISTS idx_projects_is_pinned ON projects(is_pinned);

    CREATE TABLE IF NOT EXISTS settings (
        key TEXT PRIMARY KEY,
        value TEXT NOT NULL,
        updated_at TEXT NOT NULL
    );

    CREATE TABLE IF NOT EXISTS operations (
        id TEXT PRIMARY KEY,
        project_id TEXT,
        op_type TEXT NOT NULL,
        status TEXT NOT NULL,
        started_at TEXT NOT NULL,
        completed_at TEXT,
        duration_ms INTEGER DEFAULT 0,
        details_json TEXT,
        error_message TEXT,
        FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE SET NULL
    );

    CREATE INDEX IF NOT EXISTS idx_operations_project_id ON operations(project_id);
    CREATE INDEX IF NOT EXISTS idx_operations_op_type ON operations(op_type);
    CREATE INDEX IF NOT EXISTS idx_operations_started_at ON operations(started_at DESC);

    CREATE TABLE IF NOT EXISTS report_snapshots (
        id TEXT PRIMARY KEY,
        project_id TEXT NOT NULL,
        snapshot_json TEXT NOT NULL,
        created_at TEXT NOT NULL,
        FOREIGN KEY(project_id) REFERENCES projects(id) ON DELETE CASCADE
    );

    CREATE INDEX IF NOT EXISTS idx_snapshots_project_id ON report_snapshots(project_id);
    """
]


def apply_migrations(conn: sqlite3.Connection):
    """Applies pending migrations within a transaction."""
    cursor = conn.cursor()
    cursor.execute("CREATE TABLE IF NOT EXISTS schema_version (version INTEGER PRIMARY KEY);")
    cursor.execute("SELECT MAX(version) FROM schema_version;")
    row = cursor.fetchone()
    current_version = row[0] if (row and row[0] is not None) else 0

    for idx, migration_sql in enumerate(MIGRATIONS, start=1):
        if idx > current_version:
            logger.info("Applying database migration v%d...", idx)
            cursor.executescript(migration_sql)
            cursor.execute("INSERT INTO schema_version (version) VALUES (?);", (idx,))
            conn.commit()
            logger.info("Database migration v%d applied successfully.", idx)
