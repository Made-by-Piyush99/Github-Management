"""
Activity and operation history storage.
Tracks all Git operations, status, duration, and error diagnostics.
"""

import json
import uuid
import datetime
from typing import List, Dict, Any, Optional
from .db import Database


class ActivityStore:
    def __init__(self, db: Database):
        self.db = db

    def _now(self) -> str:
        return datetime.datetime.now(datetime.timezone.utc).isoformat()

    def log_operation(
        self,
        op_type: str,
        status: str,
        project_id: Optional[str] = None,
        started_at: Optional[str] = None,
        completed_at: Optional[str] = None,
        duration_ms: int = 0,
        details: Optional[Dict[str, Any]] = None,
        error_message: Optional[str] = None,
    ) -> str:
        """Logs an operation event."""
        op_id = str(uuid.uuid4())
        s_at = started_at or self._now()
        c_at = completed_at or (self._now() if status in ("success", "failed") else None)
        details_json = json.dumps(details or {}, ensure_ascii=False)

        conn = self.db.get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute(
                """
                INSERT INTO operations (id, project_id, op_type, status, started_at, completed_at, duration_ms, details_json, error_message)
                VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);
                """,
                (op_id, project_id, op_type, status, s_at, c_at, duration_ms, details_json, error_message),
            )
            return op_id
        finally:
            conn.close()

    def update_operation(
        self,
        op_id: str,
        status: str,
        completed_at: Optional[str] = None,
        duration_ms: int = 0,
        error_message: Optional[str] = None,
        details: Optional[Dict[str, Any]] = None,
    ):
        """Updates a running operation to completed/failed status."""
        c_at = completed_at or self._now()
        details_clause = ", details_json = ?" if details is not None else ""
        params: List[Any] = [status, c_at, duration_ms, error_message]
        if details is not None:
            params.append(json.dumps(details, ensure_ascii=False))
        params.append(op_id)

        conn = self.db.get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute(
                f"""
                UPDATE operations
                SET status = ?, completed_at = ?, duration_ms = ?, error_message = ? {details_clause}
                WHERE id = ?;
                """,
                params,
            )
        finally:
            conn.close()

    def list_operations(
        self,
        project_id: Optional[str] = None,
        op_type: Optional[str] = None,
        status: Optional[str] = None,
        limit: int = 100,
        offset: int = 0,
    ) -> List[Dict[str, Any]]:
        """Queries operations with filtering and pagination."""
        clauses = []
        params: List[Any] = []

        if project_id:
            clauses.append("o.project_id = ?")
            params.append(project_id)
        if op_type:
            clauses.append("o.op_type = ?")
            params.append(op_type)
        if status:
            clauses.append("o.status = ?")
            params.append(status)

        where_sql = f"WHERE {' AND '.join(clauses)}" if clauses else ""

        sql = f"""
            SELECT o.*, p.name as project_name
            FROM operations o
            LEFT JOIN projects p ON o.project_id = p.id
            {where_sql}
            ORDER BY o.started_at DESC
            LIMIT ? OFFSET ?;
        """
        params.extend([limit, offset])

        conn = self.db.get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute(sql, params)
            results = []
            for row in cursor.fetchall():
                d = dict(row)
                try:
                    d["details"] = json.loads(d.get("details_json") or "{}")
                except Exception:
                    d["details"] = {}
                results.append(d)
            return results
        finally:
            conn.close()

    def get_last_sync_times(self, project_id: str) -> Dict[str, Optional[str]]:
        """Retrieves timestamps of the last successful push and pull for a project."""
        conn = self.db.get_connection()
        try:
            cursor = conn.cursor()
            cursor.execute(
                """
                SELECT op_type, MAX(completed_at) as last_time
                FROM operations
                WHERE project_id = ? AND status = 'success' AND op_type IN ('push', 'pull', 'fetch')
                GROUP BY op_type;
                """,
                (project_id,),
            )
            data = {"push": None, "pull": None, "fetch": None}
            for row in cursor.fetchall():
                data[row["op_type"]] = row["last_time"]
            return data
        finally:
            conn.close()
