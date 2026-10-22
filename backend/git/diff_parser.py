"""
Parses unified diff output from Git into structured data for the UI diff viewer.
"""

import re
from typing import List, Dict, Any, Optional

HUNK_HEADER_REGEX = re.compile(r"^@@\s+-(\d+)(?:,(\d+))?\s+\+(\d+)(?:,(\d+))?\s+@@(.*)$")


def parse_diff(raw_diff: str) -> List[Dict[str, Any]]:
    """
    Parses a raw unified git diff string into structured file diffs and hunks.
    """
    if not raw_diff or not raw_diff.strip():
        return []

    files: List[Dict[str, Any]] = []
    current_file: Optional[Dict[str, Any]] = None
    current_hunk: Optional[Dict[str, Any]] = None

    old_lineno = 0
    new_lineno = 0

    lines = raw_diff.splitlines()

    for line in lines:
        if line.startswith("diff --git"):
            # New file diff begins
            parts = line.split(" ")
            old_name = parts[2][2:] if len(parts) > 2 and parts[2].startswith("a/") else ""
            new_name = parts[3][2:] if len(parts) > 3 and parts[3].startswith("b/") else ""

            current_file = {
                "old_path": old_name,
                "new_path": new_name,
                "status": "modified",
                "hunks": [],
                "raw": [line],
            }
            files.append(current_file)
            current_hunk = None
            continue

        if current_file is None:
            continue

        current_file["raw"].append(line)

        if line.startswith("new file mode"):
            current_file["status"] = "added"
        elif line.startswith("deleted file mode"):
            current_file["status"] = "deleted"
        elif line.startswith("similarity index"):
            current_file["status"] = "renamed"

        # Check for hunk header
        hunk_match = HUNK_HEADER_REGEX.match(line)
        if hunk_match:
            old_start = int(hunk_match.group(1))
            old_count = int(hunk_match.group(2)) if hunk_match.group(2) else 1
            new_start = int(hunk_match.group(3))
            new_count = int(hunk_match.group(4)) if hunk_match.group(4) else 1
            section_heading = hunk_match.group(5).strip()

            old_lineno = old_start
            new_lineno = new_start

            current_hunk = {
                "header": line,
                "section": section_heading,
                "old_start": old_start,
                "old_count": old_count,
                "new_start": new_start,
                "new_count": new_count,
                "lines": [],
            }
            current_file["hunks"].append(current_hunk)
            continue

        if current_hunk is not None:
            if line.startswith("+"):
                current_hunk["lines"].append({
                    "type": "add",
                    "old_line": None,
                    "new_line": new_lineno,
                    "content": line[1:],
                })
                new_lineno += 1
            elif line.startswith("-"):
                current_hunk["lines"].append({
                    "type": "del",
                    "old_line": old_lineno,
                    "new_line": None,
                    "content": line[1:],
                })
                old_lineno += 1
            elif line.startswith(" "):
                current_hunk["lines"].append({
                    "type": "ctx",
                    "old_line": old_lineno,
                    "new_line": new_lineno,
                    "content": line[1:],
                })
                old_lineno += 1
                new_lineno += 1
            elif line == r"\ No newline at end of file":
                current_hunk["lines"].append({
                    "type": "eof",
                    "old_line": None,
                    "new_line": None,
                    "content": line,
                })

    for f in files:
        f["raw"] = "\n".join(f["raw"])

    return files
