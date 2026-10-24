"""
Git CLI execution wrapper with input validation, sanitization, and error handling.
"""

import os
import sys
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


def _resolve_real_git(path: Optional[str]) -> str:
    """
    Resolves the actual direct Git engine binary on Windows (e.g. mingw64/bin/git.exe)
    to bypass the 43KB cmd/git.exe wrapper stub which spawns visible console windows.
    """
    if not path:
        return ""
    p = path.strip()
    if not os.path.isabs(p):
        found = shutil.which(p)
        if found:
            p = found
    norm = os.path.normpath(p)
    lower = norm.lower()
    if lower.endswith(r"\cmd\git.exe") or lower.endswith(r"/cmd/git.exe") or lower.endswith(r"\bin\git.exe"):
        base = os.path.dirname(os.path.dirname(norm))
        for cand in [
            os.path.join(base, "mingw64", "bin", "git.exe"),
            os.path.join(base, "mingw32", "bin", "git.exe"),
            os.path.join(base, "usr", "bin", "git.exe"),
        ]:
            if os.path.isfile(cand):
                return cand
    return norm


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
        self._git_path = _resolve_real_git(git_path) if git_path else self._detect_git()

    def _detect_git(self) -> str:
        # Check standard mingw64 direct binaries first
        direct_candidates = [
            r"C:\Program Files\Git\mingw64\bin\git.exe",
            r"C:\Program Files (x86)\Git\mingw64\bin\git.exe",
            os.path.expandvars(r"%LOCALAPPDATA%\Programs\Git\mingw64\bin\git.exe"),
        ]
        for p in direct_candidates:
            if os.path.isfile(p):
                return p

        found = shutil.which("git")
        if found:
            resolved = _resolve_real_git(found)
            if os.path.isfile(resolved):
                return resolved
            return found

        common_paths = [
            r"C:\Program Files\Git\mingw64\bin\git.exe",
            r"C:\Program Files\Git\cmd\git.exe",
            r"C:\Program Files (x86)\Git\cmd\git.exe",
            r"C:\Program Files\Git\bin\git.exe",
        ]
        for p in common_paths:
            if os.path.isfile(p):
                return _resolve_real_git(p)
        return "git"

    @property
    def git_path(self) -> str:
        return self._git_path

    def set_git_path(self, path: Optional[str]):
        if path and path.strip():
            resolved = _resolve_real_git(path.strip())
            if os.path.isfile(resolved) or shutil.which(resolved):
                self._git_path = resolved
            else:
                raise FileNotFoundError(f"Git executable not found at: {path}")
        else:
            self._git_path = self._detect_git()

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
        Never exposes secrets in logs. Completely windowless on Windows.
        """
        # Always inject --no-pager to prevent git from invoking interactive pagers (less/more)
        full_cmd = [self._git_path, "--no-pager"] + args
        cmd_str = " ".join(full_cmd[:4]) + (" ..." if len(full_cmd) > 4 else "")
        logger.debug("Executing git in %s: %s", cwd or os.getcwd(), sanitize_text(cmd_str))

        run_env = os.environ.copy()
        # Ensure git doesn't prompt for interactive credentials on stdin or pop up pagers
        run_env["GIT_TERMINAL_PROMPT"] = "0"
        run_env["GIT_PAGER"] = "cat"
        run_env["PAGER"] = "cat"
        run_env["GIT_ASKPASS"] = ""
        run_env["SSH_ASKPASS"] = ""
        run_env["GCM_INTERACTIVE"] = "never"
        run_env["GIT_OPTIONAL_LOCKS"] = "0"
        run_env["LC_ALL"] = "C.UTF-8"
        if env:
            run_env.update(env)

        startupinfo = None
        creationflags = 0

        if sys.platform == "win32":
            creationflags = subprocess.CREATE_NO_WINDOW
            startupinfo = subprocess.STARTUPINFO()
            startupinfo.dwFlags |= subprocess.STARTF_USESHOWWINDOW
            startupinfo.wShowWindow = 0  # SW_HIDE (Never show terminal window)

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
                creationflags=creationflags,
                startupinfo=startupinfo,
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
