"""
GitHub REST API Client supporting GitHub.com and GitHub Enterprise.
Handles rate limits, token validation, repository management, and error diagnostics.
"""

import time
import logging
from typing import Dict, Any, List, Optional
import requests
from .keyring_auth import KeyringAuth

logger = logging.getLogger("DevSync.GitHubClient")

DEFAULT_API_URL = "https://api.github.com"


class GitHubClient:
    def __init__(self, auth: Optional[KeyringAuth] = None, base_url: Optional[str] = None):
        self.auth = auth or KeyringAuth()
        self.base_url = (base_url or DEFAULT_API_URL).rstrip("/")
        self.session = requests.Session()

    def set_base_url(self, url: str):
        self.base_url = (url or DEFAULT_API_URL).rstrip("/")

    def _get_headers(self) -> Dict[str, str]:
        headers = {
            "Accept": "application/vnd.github+json",
            "X-GitHub-Api-Version": "2022-11-28",
            "User-Agent": "DevSyncStudio-Desktop/1.0",
        }
        token = self.auth.get_token()
        if token:
            headers["Authorization"] = f"Bearer {token}"
        return headers

    def test_connection(self) -> Dict[str, Any]:
        """Validates connection and credentials against the GitHub API."""
        start_time = time.time()
        token = self.auth.get_token()
        if not token:
            return {
                "connected": False,
                "error": "No GitHub token configured. Please enter a Personal Access Token in Settings.",
                "user": None,
                "rate_limit": None,
            }

        url = f"{self.base_url}/user"
        try:
            resp = self.session.get(url, headers=self._get_headers(), timeout=10.0)
            latency_ms = int((time.time() - start_time) * 1000)

            if resp.status_code == 200:
                user_data = resp.json()
                scopes = resp.headers.get("x-oauth-scopes", "")
                rate_limit = self.get_rate_limit()

                return {
                    "connected": True,
                    "latency_ms": latency_ms,
                    "user": {
                        "login": user_data.get("login"),
                        "name": user_data.get("name") or user_data.get("login"),
                        "avatar_url": user_data.get("avatar_url"),
                        "html_url": user_data.get("html_url"),
                        "public_repos": user_data.get("public_repos", 0),
                        "total_private_repos": user_data.get("total_private_repos", 0),
                        "scopes": [s.strip() for s in scopes.split(",") if s.strip()],
                    },
                    "rate_limit": rate_limit,
                }
            elif resp.status_code == 401:
                return {
                    "connected": False,
                    "status_code": 401,
                    "error": "Invalid or expired GitHub Personal Access Token. Please re-authenticate.",
                }
            elif resp.status_code == 403:
                return {
                    "connected": False,
                    "status_code": 403,
                    "error": "Access forbidden. API rate limit may be exceeded or token lacks required scopes.",
                }
            else:
                return {
                    "connected": False,
                    "status_code": resp.status_code,
                    "error": f"GitHub API error ({resp.status_code}): {resp.text[:200]}",
                }

        except requests.exceptions.Timeout:
            return {"connected": False, "error": "Connection timed out connecting to GitHub API."}
        except requests.exceptions.ConnectionError:
            return {"connected": False, "error": "Network error: Unable to reach GitHub API endpoint."}
        except Exception as e:
            return {"connected": False, "error": f"Unexpected error: {str(e)}"}

    def get_rate_limit(self) -> Optional[Dict[str, Any]]:
        """Retrieves current rate limit status."""
        url = f"{self.base_url}/rate_limit"
        try:
            resp = self.session.get(url, headers=self._get_headers(), timeout=5.0)
            if resp.status_code == 200:
                data = resp.json().get("rate", {})
                return {
                    "limit": data.get("limit", 0),
                    "remaining": data.get("remaining", 0),
                    "reset": data.get("reset", 0),
                    "used": data.get("used", 0),
                }
        except Exception as e:
            logger.debug("Failed to fetch rate limit: %s", e)
        return None

    def list_repositories(self, sort: str = "updated", per_page: int = 50) -> Dict[str, Any]:
        """Lists repositories for the authenticated user."""
        url = f"{self.base_url}/user/repos"
        params = {"sort": sort, "per_page": min(per_page, 100), "affiliation": "owner,collaborator"}
        try:
            resp = self.session.get(url, headers=self._get_headers(), params=params, timeout=12.0)
            if resp.status_code == 200:
                repos = []
                for item in resp.json():
                    repos.append({
                        "id": item.get("id"),
                        "name": item.get("name"),
                        "full_name": item.get("full_name"),
                        "private": item.get("private", False),
                        "html_url": item.get("html_url"),
                        "clone_url": item.get("clone_url"),
                        "ssh_url": item.get("ssh_url"),
                        "default_branch": item.get("default_branch", "main"),
                        "description": item.get("description") or "",
                        "updated_at": item.get("updated_at"),
                        "stargazers_count": item.get("stargazers_count", 0),
                        "forks_count": item.get("forks_count", 0),
                        "open_issues_count": item.get("open_issues_count", 0),
                    })
                return {"success": True, "repositories": repos}
            return {
                "success": False,
                "error": f"Failed to list repositories ({resp.status_code}): {resp.text[:200]}",
            }
        except Exception as e:
            return {"success": False, "error": f"Network error: {str(e)}"}

    def get_repository(self, owner: str, repo: str) -> Dict[str, Any]:
        """Retrieves details for a specific repository."""
        url = f"{self.base_url}/repos/{owner}/{repo}"
        try:
            resp = self.session.get(url, headers=self._get_headers(), timeout=10.0)
            if resp.status_code == 200:
                item = resp.json()
                return {
                    "success": True,
                    "repository": {
                        "name": item.get("name"),
                        "full_name": item.get("full_name"),
                        "private": item.get("private", False),
                        "html_url": item.get("html_url"),
                        "clone_url": item.get("clone_url"),
                        "default_branch": item.get("default_branch", "main"),
                        "description": item.get("description") or "",
                        "stargazers_count": item.get("stargazers_count", 0),
                        "forks_count": item.get("forks_count", 0),
                        "open_issues_count": item.get("open_issues_count", 0),
                        "visibility": item.get("visibility", "public" if not item.get("private") else "private"),
                    },
                }
            return {"success": False, "error": f"Repository not found or inaccessible ({resp.status_code})"}
        except Exception as e:
            return {"success": False, "error": str(e)}

    def create_repository(
        self,
        name: str,
        description: str = "",
        private: bool = True,
        auto_init: bool = False,
    ) -> Dict[str, Any]:
        """Creates a new repository on GitHub."""
        clean_name = name.strip()
        if not clean_name:
            return {"success": False, "error": "Repository name cannot be empty."}

        url = f"{self.base_url}/user/repos"
        payload = {
            "name": clean_name,
            "description": description.strip(),
            "private": private,
            "auto_init": auto_init,
        }

        try:
            resp = self.session.post(url, headers=self._get_headers(), json=payload, timeout=15.0)
            if resp.status_code in (200, 201):
                item = resp.json()
                return {
                    "success": True,
                    "repository": {
                        "name": item.get("name"),
                        "full_name": item.get("full_name"),
                        "html_url": item.get("html_url"),
                        "clone_url": item.get("clone_url"),
                        "ssh_url": item.get("ssh_url"),
                        "default_branch": item.get("default_branch", "main"),
                        "private": item.get("private", True),
                    },
                }
            elif resp.status_code == 422:
                return {
                    "success": False,
                    "error": "Repository already exists on this account or name is invalid.",
                }
            return {
                "success": False,
                "error": f"Failed to create repository ({resp.status_code}): {resp.text[:200]}",
            }
        except Exception as e:
            return {"success": False, "error": str(e)}
