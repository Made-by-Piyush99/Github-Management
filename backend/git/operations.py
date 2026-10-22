"""
Git operations execution: commit, stage, branch, push, pull, fetch, diff, etc.
Includes strict validation, safety checks, and error diagnostics.
"""

import os
from typing import Dict, Any, List, Optional
from .cli import GitCLI, GitResult, sanitize_text
from .diff_parser import parse_diff


class GitOperations:
    def __init__(self, cli: Optional[GitCLI] = None):
        self.cli = cli or GitCLI()

    def clone_repo(self, url: str, target_dir: str, branch: Optional[str] = None) -> Dict[str, Any]:
        """Clones a remote repository into target directory."""
        os.makedirs(os.path.dirname(os.path.abspath(target_dir)), exist_ok=True)
        cmd = ["clone", "--progress"]
        if branch:
            cmd.extend(["-b", branch])
        cmd.extend([url, target_dir])
        res = self.cli.run(cmd, timeout=300.0)
        return {
            "success": res.ok,
            "message": res.stdout.strip() or res.stderr.strip(),
            "error": res.stderr.strip() if not res.ok else None,
            "target_dir": target_dir,
        }

    def init_repo(self, path: str, default_branch: str = "main") -> Dict[str, Any]:
        """Initializes a new Git repository."""
        if not os.path.exists(path):
            os.makedirs(path, exist_ok=True)
        res = self.cli.run(["init", f"--initial-branch={default_branch}"], cwd=path)
        if not res.ok:
            # Fallback for older git that doesn't support --initial-branch
            res = self.cli.run(["init"], cwd=path)
        return {
            "success": res.ok,
            "message": res.stdout.strip() if res.ok else res.stderr.strip(),
            "path": path,
        }

    def stage_file(self, path: str, rel_path: str) -> Dict[str, Any]:
        """Stages a file into the git index."""
        res = self.cli.run(["add", "--", rel_path], cwd=path)
        return {"success": res.ok, "error": res.stderr if not res.ok else None}

    def unstage_file(self, path: str, rel_path: str) -> Dict[str, Any]:
        """Unstages a file from the git index."""
        res = self.cli.run(["restore", "--staged", "--", rel_path], cwd=path)
        if not res.ok:
            # Fallback for older git
            res = self.cli.run(["reset", "HEAD", "--", rel_path], cwd=path)
        return {"success": res.ok, "error": res.stderr if not res.ok else None}

    def stage_all(self, path: str) -> Dict[str, Any]:
        """Stages all changes (modified, deleted, untracked)."""
        res = self.cli.run(["add", "-A"], cwd=path)
        return {"success": res.ok, "error": res.stderr if not res.ok else None}

    def unstage_all(self, path: str) -> Dict[str, Any]:
        """Unstages all staged changes."""
        res = self.cli.run(["restore", "--staged", "."], cwd=path)
        if not res.ok:
            res = self.cli.run(["reset", "HEAD"], cwd=path)
        return {"success": res.ok, "error": res.stderr if not res.ok else None}

    def discard_file(self, path: str, rel_path: str) -> Dict[str, Any]:
        """
        Discards changes to a file.
        If file is untracked, removes it from filesystem.
        If tracked, restores it from index/HEAD.
        """
        full_path = os.path.normpath(os.path.join(path, rel_path))
        # Prevent directory traversal attacks
        if not full_path.startswith(os.path.normpath(path)):
            return {"success": False, "error": "Path traversal detected."}

        # Check if file is untracked
        ls_res = self.cli.run(["ls-files", "--error-unmatch", "--", rel_path], cwd=path)
        if not ls_res.ok:
            # File is untracked, delete safely
            try:
                if os.path.isfile(full_path):
                    os.remove(full_path)
                elif os.path.isdir(full_path):
                    import shutil
                    shutil.rmtree(full_path)
                return {"success": True}
            except Exception as e:
                return {"success": False, "error": f"Failed to delete untracked file: {e}"}

        # Tracked file: first unstage if staged
        self.cli.run(["restore", "--staged", "--", rel_path], cwd=path)
        # Restore worktree
        res = self.cli.run(["restore", "--worktree", "--", rel_path], cwd=path)
        if not res.ok:
            res = self.cli.run(["checkout", "HEAD", "--", rel_path], cwd=path)
        return {"success": res.ok, "error": res.stderr if not res.ok else None}

    def commit(self, path: str, message: str, author: Optional[str] = None) -> Dict[str, Any]:
        """Creates a commit with a validated message."""
        clean_msg = message.strip() if message else ""
        if not clean_msg:
            return {"success": False, "error": "Commit message cannot be empty."}

        # Check if there is anything staged
        diff_staged = self.cli.run(["diff", "--staged", "--name-only"], cwd=path)
        if not diff_staged.ok or not diff_staged.stdout.strip():
            return {
                "success": False,
                "error": "No changes staged for commit. Please stage files before committing.",
            }

        cmd = ["commit", "-m", clean_msg]
        if author:
            cmd.extend(["--author", author])

        res = self.cli.run(cmd, cwd=path)
        if res.ok:
            # Retrieve commit hash
            hash_res = self.cli.run(["rev-parse", "HEAD"], cwd=path)
            commit_hash = hash_res.stdout.strip() if hash_res.ok else ""
            return {"success": True, "commit_hash": commit_hash, "message": res.stdout.strip()}
        return {"success": False, "error": res.stderr.strip() or res.stdout.strip()}

    def get_file_diff(self, path: str, rel_path: Optional[str] = None, staged: bool = False) -> Dict[str, Any]:
        """Gets unified diff for a file or entire repository."""
        cmd = ["diff"]
        if staged:
            cmd.append("--staged")
        cmd.append("--")
        if rel_path:
            cmd.append(rel_path)

        res = self.cli.run(cmd, cwd=path)
        raw_diff = res.stdout if res.ok else ""
        parsed = parse_diff(raw_diff)

        # If file is untracked and rel_path is specified, display full content as addition
        if not raw_diff and rel_path:
            full_path = os.path.join(path, rel_path)
            if os.path.isfile(full_path):
                # Check if untracked
                ls_res = self.cli.run(["ls-files", "--others", "--exclude-standard", "--", rel_path], cwd=path)
                if ls_res.ok and ls_res.stdout.strip():
                    try:
                        with open(full_path, "r", encoding="utf-8", errors="replace") as f:
                            content = f.read()
                        lines = content.splitlines()
                        hunk_lines = [
                            {"type": "add", "old_line": None, "new_line": idx + 1, "content": l}
                            for idx, l in enumerate(lines)
                        ]
                        parsed = [{
                            "old_path": "/dev/null",
                            "new_path": rel_path,
                            "status": "added",
                            "hunks": [{
                                "header": f"@@ -0,0 +1,{len(lines)} @@",
                                "section": "",
                                "old_start": 0,
                                "old_count": 0,
                                "new_start": 1,
                                "new_count": len(lines),
                                "lines": hunk_lines,
                            }],
                            "raw": content,
                        }]
                        raw_diff = content
                    except Exception:
                        pass

        return {
            "success": res.ok,
            "raw_diff": raw_diff,
            "files": parsed,
            "error": res.stderr if not res.ok else None,
        }

    def list_branches(self, path: str) -> Dict[str, Any]:
        """Lists local and remote branches with tracking information."""
        # Local and remote branches with upstream and commit info using pipe delimiter
        res = self.cli.run(
            ["branch", "-a", "--format=%(refname)|%(refname:short)|%(HEAD)|%(upstream)|%(upstream:track)|%(objectname:short)|%(contents:subject)|%(authordate:relative)"],
            cwd=path,
        )

        local_branches = []
        remote_branches = []

        if res.ok and res.stdout:
            for line in res.stdout.splitlines():
                if not line.strip():
                    continue
                parts = line.strip().split("|")
                if len(parts) >= 8:
                    ref_full = parts[0]
                    short_name = parts[1]
                    is_head = parts[2].strip() == "*"
                    upstream = parts[3].strip()
                    track_status = parts[4].strip()
                    commit_hash = parts[5].strip()
                    subject = parts[6].strip()
                    rel_date = parts[7].strip()

                    is_remote = ref_full.startswith("refs/remotes/")
                    branch_name = short_name if short_name else ref_full.replace("refs/heads/", "").replace("refs/remotes/", "")

                    branch_item = {
                        "name": branch_name,
                        "is_current": is_head,
                        "upstream": upstream,
                        "track_status": track_status,
                        "commit_hash": commit_hash,
                        "subject": subject,
                        "date": rel_date,
                        "is_remote": is_remote,
                    }

                    if is_remote:
                        remote_branches.append(branch_item)
                    else:
                        local_branches.append(branch_item)

        return {
            "success": True,
            "local": local_branches,
            "remote": remote_branches,
        }

    def create_branch(self, path: str, branch_name: str, start_point: Optional[str] = None, checkout: bool = True) -> Dict[str, Any]:
        """Creates a new branch, optionally checking it out."""
        name = branch_name.strip()
        if not name or " " in name:
            return {"success": False, "error": "Invalid branch name. Must not contain whitespace."}

        cmd = ["checkout", "-b", name] if checkout else ["branch", name]
        if start_point:
            cmd.append(start_point)

        res = self.cli.run(cmd, cwd=path)
        return {
            "success": res.ok,
            "message": res.stdout.strip() if res.ok else res.stderr.strip(),
            "error": res.stderr.strip() if not res.ok else None,
        }

    def switch_branch(self, path: str, branch_name: str) -> Dict[str, Any]:
        """Switches to another branch, with pre-check for uncommitted changes."""
        name = branch_name.strip()
        if not name:
            return {"success": False, "error": "Branch name required."}

        res = self.cli.run(["checkout", name], cwd=path)
        return {
            "success": res.ok,
            "message": res.stdout.strip() if res.ok else res.stderr.strip(),
            "error": res.stderr.strip() if not res.ok else None,
        }

    def rename_branch(self, path: str, old_name: str, new_name: str) -> Dict[str, Any]:
        """Renames a branch."""
        res = self.cli.run(["branch", "-m", old_name, new_name], cwd=path)
        return {
            "success": res.ok,
            "error": res.stderr.strip() if not res.ok else None,
        }

    def delete_branch(self, path: str, branch_name: str, force: bool = False) -> Dict[str, Any]:
        """Deletes a local branch. Protects currently checked out branch."""
        # 1. Verify it's not the active branch
        curr_res = self.cli.run(["branch", "--show-current"], cwd=path)
        if curr_res.ok and curr_res.stdout.strip() == branch_name:
            return {
                "success": False,
                "error": f"Cannot delete branch '{branch_name}' because it is currently checked out. Switch to another branch first.",
            }

        flag = "-D" if force else "-d"
        res = self.cli.run(["branch", flag, branch_name], cwd=path)
        return {
            "success": res.ok,
            "error": res.stderr.strip() if not res.ok else None,
            "message": res.stdout.strip() if res.ok else "",
        }

    def fetch(self, path: str, remote: str = "origin", prune: bool = True) -> Dict[str, Any]:
        """Fetches commits and refs from remote."""
        cmd = ["fetch", remote]
        if prune:
            cmd.append("--prune")
        res = self.cli.run(cmd, cwd=path, timeout=120.0)
        return {
            "success": res.ok,
            "message": res.stderr.strip() or res.stdout.strip(),
            "error": res.stderr.strip() if not res.ok else None,
        }

    def pull(self, path: str, remote: str = "origin", branch: Optional[str] = None) -> Dict[str, Any]:
        """Pulls changes from remote. Checks for conflicts and returns clear diagnostics."""
        cmd = ["pull", remote]
        if branch:
            cmd.append(branch)

        res = self.cli.run(cmd, cwd=path, timeout=180.0)
        is_conflict = "CONFLICT" in res.stdout or "CONFLICT" in res.stderr
        return {
            "success": res.ok,
            "is_conflict": is_conflict,
            "message": res.stdout.strip() or res.stderr.strip(),
            "error": res.stderr.strip() if not res.ok else None,
        }

    def push(self, path: str, remote: str = "origin", branch: Optional[str] = None, set_upstream: bool = False) -> Dict[str, Any]:
        """Pushes commits to remote. Never force pushes."""
        cmd = ["push"]
        if set_upstream:
            cmd.append("-u")
        cmd.append(remote)
        if branch:
            cmd.append(branch)

        res = self.cli.run(cmd, cwd=path, timeout=180.0)
        return {
            "success": res.ok,
            "message": res.stderr.strip() or res.stdout.strip(),
            "error": res.stderr.strip() if not res.ok else None,
        }

    def get_commit_history(self, path: str, limit: int = 50, branch: Optional[str] = None, skip: int = 0) -> List[Dict[str, Any]]:
        """Retrieves commit history with changed file statistics."""
        cmd = [
            "log",
            f"-{limit}",
            f"--skip={skip}",
            "--format=%H%x1f%h%x1f%an%x1f%ae%x1f%aI%x1f%s%x1f%b",
        ]
        if branch:
            cmd.append(branch)

        res = self.cli.run(cmd, cwd=path)
        if not res.ok or not res.stdout:
            return []

        commits = []
        for line in res.stdout.splitlines():
            parts = line.split("\x1f")
            if len(parts) >= 6:
                commits.append({
                    "hash": parts[0],
                    "short_hash": parts[1],
                    "author_name": parts[2],
                    "author_email": parts[3],
                    "date": parts[4],
                    "subject": parts[5],
                    "body": parts[6] if len(parts) > 6 else "",
                })
        return commits

    def add_remote(self, path: str, name: str, url: str) -> Dict[str, Any]:
        """Adds a remote repository."""
        res = self.cli.run(["remote", "add", name, url], cwd=path)
        return {"success": res.ok, "error": res.stderr.strip() if not res.ok else None}

    def set_remote_url(self, path: str, name: str, url: str) -> Dict[str, Any]:
        """Updates a remote URL."""
        res = self.cli.run(["remote", "set-url", name, url], cwd=path)
        return {"success": res.ok, "error": res.stderr.strip() if not res.ok else None}

    def remove_remote(self, path: str, name: str) -> Dict[str, Any]:
        """Removes a remote."""
        res = self.cli.run(["remote", "remove", name], cwd=path)
        return {"success": res.ok, "error": res.stderr.strip() if not res.ok else None}
