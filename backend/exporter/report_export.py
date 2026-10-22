"""
Export utilities for Project Health Reports and Activity Logs to JSON and CSV.
Never includes secrets or tokens in exported files.
"""

import csv
import json
import os
from typing import Dict, Any, List


def export_report_json(report: Dict[str, Any], output_path: str) -> bool:
    """Exports a project health report to JSON."""
    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(report, f, indent=2, ensure_ascii=False)
    return True


def export_report_csv(report: Dict[str, Any], output_path: str) -> bool:
    """Exports key project health metrics to CSV."""
    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    rows = [
        ("Metric", "Value"),
        ("Project Path", report.get("path", "")),
        ("Current Branch", report.get("current_branch", "")),
        ("Health Score", str(report.get("health_score", 0))),
        ("Grade", report.get("grade", "")),
        ("Status", report.get("status", "")),
        ("Total Commits", str(report.get("total_commits", 0))),
        ("Contributors Count", str(report.get("contributors_count", 0))),
        ("Uncommitted Files", str(report.get("uncommitted_count", 0))),
        ("Staged Files", str(report.get("staged_count", 0))),
        ("Ahead Commits", str(report.get("ahead", 0))),
        ("Behind Commits", str(report.get("behind", 0))),
        ("Last Push", report.get("last_successful_push") or "N/A"),
        ("Last Pull", report.get("last_successful_pull") or "N/A"),
        ("Generated At", report.get("generated_at", "")),
    ]

    with open(output_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.writer(f)
        writer.writerows(rows)
    return True


def export_activity_json(operations: List[Dict[str, Any]], output_path: str) -> bool:
    """Exports operations log to JSON."""
    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    with open(output_path, "w", encoding="utf-8") as f:
        json.dump(operations, f, indent=2, ensure_ascii=False)
    return True


def export_activity_csv(operations: List[Dict[str, Any]], output_path: str) -> bool:
    """Exports operations log to CSV."""
    os.makedirs(os.path.dirname(os.path.abspath(output_path)), exist_ok=True)
    fieldnames = ["id", "project_id", "project_name", "op_type", "status", "started_at", "completed_at", "duration_ms", "error_message"]
    with open(output_path, "w", newline="", encoding="utf-8") as f:
        writer = csv.DictWriter(f, fieldnames=fieldnames, extrasaction="ignore")
        writer.writeheader()
        for op in operations:
            writer.writerow(op)
    return True
