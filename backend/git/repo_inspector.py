"""
Comprehensive Git repository inspector.
Reads the authoritative state of a local repository.
"""

import os
import re
from typing import Dict, Any, List, Optional
from .cli import GitCLI


class RepoInspector:
    def __init__(self, cli: Optional[GitCLI] = None):
        self.cli = cli or GitCLI()

    def is_git_repo(self, path: str) -> bool:
        """Checks if a directory is inside a valid git working tree."""
        if not path or not os.path.isdir(path):
            return False
        res = self.cli.run(["rev-parse", "--is-inside-work-tree"], cwd=path)
        return res.ok and res.stdout.strip() == "true"

    def inspect(self, path: str) -> Dict[str, Any]:
        """
        Inspects the repository state completely and returns a structured dictionary.
        Returns empty or invalid indicator if not a git repository.
        """
        if not os.path.exists(path):
            return {
                "is_git_repo": False,
                "exists": False,
                "error": "Directory does not exist",
                "status": "Missing",
            }

        if not self.is_git_repo(path):
            return {
                "is_git_repo": False,
                "exists": True,
                "error": "Not a Git repository",
                "status": "Not Git",
            }

        # 1. Current Branch
        branch_res = self.cli.run(["branch", "--show-current"], cwd=path)
        current_branch = branch_res.stdout.strip() if branch_res.ok else ""
        if not current_branch:
            # Might be detached HEAD
            head_res = self.cli.run(["rev-parse", "--abbrev-ref", "HEAD"], cwd=path)
            current_branch = head_res.stdout.strip() if head_res.ok else "HEAD"

        # 2. Check if repository has any commits yet
        has_commits = True
        count_res = self.cli.run(["rev-list", "--count", "HEAD"], cwd=path)
        total_commits = 0
        if count_res.ok:
            try:
                total_commits = int(count_res.stdout.strip())
            except ValueError:
                total_commits = 0
        else:
            has_commits = False

        # 3. Head commit info
        last_commit: Optional[Dict[str, Any]] = None
        if has_commits:
            log_res = self.cli.run(
                ["log", "-1", "--format=%H%x1f%h%x1f%an%x1f%ae%x1f%aI%x1f%s"],
                cwd=path,
            )
            if log_res.ok and log_res.stdout.strip():
                parts = log_res.stdout.strip().split("\x1f")
                if len(parts) >= 6:
                    last_commit = {
                        "hash": parts[0],
                        "short_hash": parts[1],
                        "author_name": parts[2],
                        "author_email": parts[3],
                        "date": parts[4],
                        "message": parts[5],
                    }

        # 4. Upstream tracking & Ahead / Behind counts
        upstream = ""
        ahead = 0
        behind = 0
        if has_commits and current_branch and current_branch != "HEAD":
            up_res = self.cli.run(
                ["rev-parse", "--abbrev-ref", "--symbolic-full-name", "@{u}"],
                cwd=path,
            )
            if up_res.ok:
                upstream = up_res.stdout.strip()
                # Ahead/behind count
                ab_res = self.cli.run(
                    ["rev-list", "--left-right", "--count", f"HEAD...{upstream}"],
                    cwd=path,
                )
                if ab_res.ok and ab_res.stdout.strip():
                    ab_parts = ab_res.stdout.strip().split()
                    if len(ab_parts) >= 2:
                        try:
                            ahead = int(ab_parts[0])
                            behind = int(ab_parts[1])
                        except ValueError:
                            pass

        # 5. Working tree file status (porcelain v1)
        status_res = self.cli.run(["status", "--porcelain=v1", "-uall"], cwd=path)
        modified_count = 0
        staged_count = 0
        untracked_count = 0
        conflict_count = 0

        files_summary: List[Dict[str, Any]] = []

        if status_res.ok and status_res.stdout:
            for line in status_res.stdout.splitlines():
                if len(line) < 3:
                    continue
                x = line[0]  # Staged index status
                y = line[1]  # Worktree status
                filepath = line[3:].strip()

                is_conflict = (x == "U" or y == "U" or (x == "A" and y == "A") or (x == "D" and y == "D"))
                is_staged = x in ("M", "A", "D", "R", "C")
                is_modified = y in ("M", "D")
                is_untracked = (x == "?" and y == "?")

                if is_conflict:
                    conflict_count += 1
                if is_staged:
                    staged_count += 1
                if is_modified:
                    modified_count += 1
                if is_untracked:
                    untracked_count += 1

                files_summary.append({
                    "path": filepath,
                    "index_status": x,
                    "worktree_status": y,
                    "is_staged": is_staged,
                    "is_modified": is_modified,
                    "is_untracked": is_untracked,
                    "is_conflict": is_conflict,
                })

        uncommitted_count = len(files_summary)

        # 6. Remotes
        remotes_res = self.cli.run(["remote", "-v"], cwd=path)
        remotes_dict: Dict[str, Dict[str, str]] = {}
        primary_remote_url = ""
        has_github_remote = False

        if remotes_res.ok and remotes_res.stdout:
            for rline in remotes_res.stdout.splitlines():
                parts = rline.split()
                if len(parts) >= 3:
                    rname = parts[0]
                    raw_url = parts[1]
                    rurl = re.sub(r'https?://[^@]+@', 'https://', raw_url)
                    rtype = parts[2].strip("()")
                    if rname not in remotes_dict:
                        remotes_dict[rname] = {"name": rname, "fetch": "", "push": ""}
                    if rtype == "fetch":
                        remotes_dict[rname]["fetch"] = rurl
                    elif rtype == "push":
                        remotes_dict[rname]["push"] = rurl

            if "origin" in remotes_dict:
                primary_remote_url = remotes_dict["origin"].get("fetch") or remotes_dict["origin"].get("push", "")
            elif remotes_dict:
                first_key = next(iter(remotes_dict))
                primary_remote_url = remotes_dict[first_key].get("fetch", "")

            if "github.com" in primary_remote_url.lower():
                has_github_remote = True

        # 7. Synthesize overall status string
        if not has_commits:
            computed_status = "Initial (Empty)"
        elif conflict_count > 0:
            computed_status = "Conflict"
        elif uncommitted_count > 0:
            computed_status = "Modified"
        elif ahead > 0 and behind > 0:
            computed_status = "Diverged"
        elif ahead > 0:
            computed_status = "Ahead"
        elif behind > 0:
            computed_status = "Behind"
        elif upstream:
            computed_status = "Synced"
        elif primary_remote_url:
            computed_status = "Untracked Remote"
        else:
            computed_status = "No Remote"

        return {
            "is_git_repo": True,
            "exists": True,
            "path": path,
            "current_branch": current_branch,
            "has_commits": has_commits,
            "total_commits": total_commits,
            "last_commit": last_commit,
            "upstream": upstream,
            "ahead": ahead,
            "behind": behind,
            "status": computed_status,
            "uncommitted_count": uncommitted_count,
            "staged_count": staged_count,
            "modified_count": modified_count,
            "untracked_count": untracked_count,
            "conflict_count": conflict_count,
            "files": files_summary,
            "remotes": list(remotes_dict.values()),
            "primary_remote_url": primary_remote_url,
            "has_github_remote": has_github_remote,
        }
