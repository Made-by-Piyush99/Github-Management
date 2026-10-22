"""
Git CLI execution wrapper with input validation, sanitization, and error handling.
"""

import os
import re
import shutil
import subprocess
import logging
from dataclasses import dataclass
from typing import List, Optional, Tuple, Dict, Any

logger = logging.getLogger("DevSync.GitCli")

TOKEN_URL_REGEX = re.compile(r"https?://(?:[^:]+:[^@]+|[^@]+)@github\.com")


def sanitize_text(text: str) -> str:
    """Removes tokens, passwords, or credentials from git output or URLs."""
    if not text:
        return ""
    return TOKEN_URL_REGEX.sub("https://***@github.com", text)


@dataclass
class GitResult:
    returncode: int
    stdout: str
    stderr: str
    command: List[str]

    @property
    def ok(self) -> bool:
        return self.returncode == 0


class GitCLI:
    """Executes Git CLI commands safely without shell interpolation."""

    def __init__(self, git_path: Optional[str] = None):
        self._git_path = git_path or self._detect_git()

    def _detect_git(self) -> str:
        found = shutil.which("git")
        if found:
            return found
        # Common Windows paths
        common_paths = [
            r"C:\Program Files\Git\cmd\git.exe",
            r"C:\Program Files (x86)\Git\cmd\git.exe",
            r"C:\Program Files\Git\bin\git.exe",
        ]
        for p in common_paths:
            if os.path.isfile(p):
                return p
        return "git"

    @property
    def git_path(self) -> str:
        return self._git_path

    def set_git_path(self, path: str):
        if path and (os.path.isfile(path) or shutil.which(path)):
            self._git_path = path
        else:
            raise FileNotFoundError(f"Git executable not found at: {path}")

    def get_version(self) -> str:
        """Returns the installed Git version string."""
        res = self.run(["--version"])
        if res.ok:
            return res.stdout.strip()
        return "Unknown"

    def run(
        self,
        args: List[str],
        cwd: Optional[str] = None,
        timeout: float = 60.0,
        env: Optional[Dict[str, str]] = None,
        check: bool = False,
    ) -> GitResult:
        """
        Runs a git command with explicit argument lists (no shell=True).
        Never exposes secrets in logs.
        """
        full_cmd = [self._git_path] + args
        cmd_str = " ".join(full_cmd[:4]) + (" ..." if len(full_cmd) > 4 else "")
        logger.debug("Executing git in %s: %s", cwd or os.getcwd(), sanitize_text(cmd_str))

        run_env = os.environ.copy()
        # Ensure git doesn't prompt for interactive credentials on stdin
        run_env["GIT_TERMINAL_PROMPT"] = "0"
        run_env["LC_ALL"] = "C.UTF-8"
        if env:
            run_env.update(env)

        try:
            proc = subprocess.run(
                full_cmd,
                cwd=cwd,
                stdin=subprocess.DEVNULL,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                encoding="utf-8",
                errors="replace",
                timeout=timeout,
                check=False,
            )
            stdout = proc.stdout
            stderr = proc.stderr
            returncode = proc.returncode

        except subprocess.TimeoutExpired as te:
            logger.error("Git command timed out after %s seconds: %s", timeout, cmd_str)
            stdout = te.stdout or "" if isinstance(te.stdout, str) else ""
            stderr = f"Command timed out after {timeout} seconds."
            returncode = -1
        except FileNotFoundError:
            logger.error("Git executable not found at %s", self._git_path)
            stdout = ""
            stderr = f"Git executable not found: {self._git_path}"
            returncode = -2
        except Exception as e:
            logger.exception("Unexpected error executing git: %s", e)
            stdout = ""
            stderr = f"Execution error: {str(e)}"
            returncode = -3

        res = GitResult(
            returncode=returncode,
            stdout=stdout,
            stderr=sanitize_text(stderr),
            command=[sanitize_text(a) for a in full_cmd],
        )

        if check and not res.ok:
            raise RuntimeError(f"Git command failed ({res.returncode}): {res.stderr or res.stdout}")

        return res
