"""
Project metadata repository for SQLite persistence.
"""

import os
import uuid
import datetime
from typing import List, Dict, Any, Optional
from .db import Database


class ProjectStore:
    def __init__(self, db: Database):
        self.db = db

    def _now(self) -> str:
        return datetime.datetime.now(datetime.timezone.utc).isoformat()

    def add_project(
        self,
        name: str,
        local_path: str,
        git_remote: Optional[str] = None,
        default_branch: str = "main",
    ) -> Dict[str, Any]:
        """Registers a new project."""
        norm_path = os.path.normpath(os.path.abspath(local_path))
        existing = self.get_project_by_path(norm_path)
        if existing:
            raise ValueError(f"Project already registered at this path: {norm_path}")

        proj_id = str(uuid.uuid4())
        now = self._now()
        display_name = name.strip() or os.path.basename(norm_path) or "Project"

        conn = self.db.get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute(
                """
                INSERT INTO projects (id, name, local_path, git_remote, default_branch, is_pinned, created_at, updated_at)
                VALUES (?, ?, ?, ?, ?, 0, ?, ?);
                """,
                (proj_id, display_name, norm_path, git_remote, default_branch, now, now),
            )
            return self.get_project(proj_id)
        finally:
            conn.close()

    def get_project(self, project_id: str) -> Optional[Dict[str, Any]]:
        """Retrieves a single project by ID."""
        conn = self.db.get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM projects WHERE id = ?;", (project_id,))
            row = cursor.fetchone()
            return dict(row) if row else None
        finally:
            conn.close()

    def get_project_by_path(self, local_path: str) -> Optional[Dict[str, Any]]:
        """Retrieves a project by path."""
        norm_path = os.path.normpath(os.path.abspath(local_path))
        conn = self.db.get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM projects WHERE local_path = ?;", (norm_path,))
            row = cursor.fetchone()
            return dict(row) if row else None
        finally:
            conn.close()

    def list_projects(self) -> List[Dict[str, Any]]:
        """Lists all projects ordered by pinned status and update time."""
        conn = self.db.get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute("SELECT * FROM projects ORDER BY is_pinned DESC, updated_at DESC;")
            return [dict(r) for r in cursor.fetchall()]
        finally:
            conn.close()

    def update_project(self, project_id: str, **kwargs) -> Optional[Dict[str, Any]]:
        """Updates project metadata fields."""
        allowed = {"name", "local_path", "git_remote", "default_branch", "is_pinned"}
        updates = {k: v for k, v in kwargs.items() if k in allowed}
        if not updates:
            return self.get_project(project_id)

        updates["updated_at"] = self._now()
        set_clause = ", ".join(f"{k} = ?" for k in updates.keys())
        values = list(updates.values()) + [project_id]

        conn = self.db.get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute(f"UPDATE projects SET {set_clause} WHERE id = ?;", values)
            return self.get_project(project_id)
        finally:
            conn.close()

    def delete_project(self, project_id: str) -> bool:
        """Removes a project record from SQLite without deleting physical files."""
        conn = self.db.get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute("DELETE FROM projects WHERE id = ?;", (project_id,))
            return cursor.rowcount > 0
        finally:
            conn.close()

    def set_pinned(self, project_id: str, is_pinned: bool) -> Optional[Dict[str, Any]]:
        """Pins or unpins a project."""
        return self.update_project(project_id, is_pinned=1 if is_pinned else 0)
