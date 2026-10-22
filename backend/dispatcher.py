"""
Command dispatcher that connects incoming IPC requests to backend modules.
Maintains activity logging and execution timing for all operations.
"""

import os
import time
import logging
from typing import Dict, Any, Optional

from .git.cli import GitCLI
from .git.repo_inspector import RepoInspector
from .git.operations import GitOperations
from .github.keyring_auth import KeyringAuth
from .github.client import GitHubClient
from .storage.db import Database
from .storage.project_store import ProjectStore
from .storage.activity_store import ActivityStore
from .storage.settings_store import SettingsStore
from .reports.health import HealthReportGenerator
from .exporter.report_export import (
    export_report_json,
    export_report_csv,
    export_activity_json,
    export_activity_csv,
)

logger = logging.getLogger("DevSync.Dispatcher")


class Dispatcher:
    def __init__(self, db_path: Optional[str] = None):
        self.db = Database(db_path)
        self.project_store = ProjectStore(self.db)
        self.activity_store = ActivityStore(self.db)
        self.settings_store = SettingsStore(self.db)

        # Git setup
        git_custom_path = self.settings_store.get("git_path") or None
        self.git_cli = GitCLI(git_custom_path)
        self.repo_inspector = RepoInspector(self.git_cli)
        self.git_ops = GitOperations(self.git_cli)

        # GitHub setup
        self.keyring_auth = KeyringAuth()
        gh_url = self.settings_store.get("github_api_url") or "https://api.github.com"
        self.github_client = GitHubClient(self.keyring_auth, gh_url)

        # Reports setup
        self.report_gen = HealthReportGenerator(
            self.git_cli, self.repo_inspector, self.activity_store, self.github_client
        )

    def dispatch(self, cmd: str, args: Dict[str, Any]) -> Any:
        """Executes a command by name with provided arguments."""
        handler_name = f"_cmd_{cmd.replace('.', '_')}"
        handler = getattr(self, handler_name, None)
        if not handler:
            raise ValueError(f"Unknown command: '{cmd}'")
        return handler(args or {})

    # ==========================
    # Project Handlers
    # ==========================

    def _cmd_projects_list(self, args: Dict[str, Any]) -> Any:
        projects = self.project_store.list_projects()
        enriched = []
        for p in projects:
            lpath = p["local_path"]
            info = self.repo_inspector.inspect(lpath)
            last_sync = self.activity_store.get_last_sync_times(p["id"])

            p_data = dict(p)
            p_data.update({
                "exists": info.get("exists", False),
                "is_git_repo": info.get("is_git_repo", False),
                "current_branch": info.get("current_branch", ""),
                "status": info.get("status", "Unknown"),
                "uncommitted_count": info.get("uncommitted_count", 0),
                "ahead": info.get("ahead", 0),
                "behind": info.get("behind", 0),
                "last_commit": info.get("last_commit"),
                "primary_remote_url": info.get("primary_remote_url") or p.get("git_remote") or "",
                "has_github_remote": info.get("has_github_remote", False),
                "last_successful_push": last_sync.get("push"),
                "last_successful_pull": last_sync.get("pull"),
            })
            enriched.append(p_data)
        return enriched

    def _cmd_projects_add(self, args: Dict[str, Any]) -> Any:
        path = args.get("path", "").strip()
        name = args.get("name", "").strip()
        if not path:
            raise ValueError("Project path is required.")
        if not os.path.exists(path):
            raise FileNotFoundError(f"Directory not found: {path}")

        # Check git info
        info = self.repo_inspector.inspect(path)
        remote_url = info.get("primary_remote_url", "")
        default_b = info.get("current_branch") or "main"

        proj = self.project_store.add_project(
            name=name or os.path.basename(path) or "Project",
            local_path=path,
            git_remote=remote_url,
            default_branch=default_b,
        )

        self.activity_store.log_operation(
            op_type="project_add",
            status="success",
            project_id=proj["id"],
            details={"path": path, "name": proj["name"]},
        )
        return proj

    def _cmd_projects_remove(self, args: Dict[str, Any]) -> Any:
        proj_id = args.get("id")
        if not proj_id:
            raise ValueError("Project id required.")
        proj = self.project_store.get_project(proj_id)
        success = self.project_store.delete_project(proj_id)
        if success:
            self.activity_store.log_operation(
                op_type="project_remove",
                status="success",
                project_id=proj_id,
                details={"name": proj.get("name") if proj else ""},
            )
        return {"success": success}

    def _cmd_projects_set_pinned(self, args: Dict[str, Any]) -> Any:
        proj_id = args.get("id")
        is_pinned = bool(args.get("is_pinned", False))
        return self.project_store.set_pinned(proj_id, is_pinned)

    def _cmd_projects_get_details(self, args: Dict[str, Any]) -> Any:
        proj_id = args.get("id")
        proj = self.project_store.get_project(proj_id)
        if not proj:
            raise ValueError(f"Project with ID '{proj_id}' not found.")

        lpath = proj["local_path"]
        repo_info = self.repo_inspector.inspect(lpath)
        report = self.report_gen.generate(proj_id, lpath, proj.get("git_remote"))
        commits = self.git_ops.get_commit_history(lpath, limit=30) if repo_info.get("is_git_repo") else []

        return {
            "project": proj,
            "repo_info": repo_info,
            "report": report,
            "commits": commits,
        }

    # ==========================
    # Git Handlers
    # ==========================

    def _cmd_git_clone(self, args: Dict[str, Any]) -> Any:
        url = args.get("url", "").strip()
        target_dir = args.get("target_dir", "").strip()
        name = args.get("name", "").strip()
        if not url:
            raise ValueError("Repository URL is required for clone.")
        if not target_dir:
            # Default target directory
            repo_base = url.rstrip("/").split("/")[-1].replace(".git", "")
            base_projects = os.path.join(os.path.expanduser("~"), "DevSyncProjects")
            target_dir = os.path.join(base_projects, repo_base)

        norm_target = os.path.normpath(os.path.abspath(target_dir))
        if os.path.exists(norm_target) and os.listdir(norm_target):
            raise ValueError(f"Target folder is not empty: {norm_target}")

        # Inject PAT token if available for seamless private/public clone
        token = self.keyring_auth.get_token()
        clone_url = url
        if token and "github.com" in url.lower() and "@" not in url:
            clone_url = url.replace("https://github.com", f"https://x-access-token:{token}@github.com")

        t0 = time.time()
        res = self.git_ops.clone_repo(clone_url, norm_target)
        dur = int((time.time() - t0) * 1000)

        if res.get("success"):
            # Set remote url to clean URL without token
            self.git_ops.set_remote_url(norm_target, "origin", url)
            info = self.repo_inspector.inspect(norm_target)
            proj_name = name or os.path.basename(norm_target)
            default_b = info.get("current_branch") or "main"

            proj = self.project_store.add_project(
                name=proj_name,
                local_path=norm_target,
                git_remote=url,
                default_branch=default_b,
            )
            self.activity_store.log_operation(
                op_type="clone",
                status="success",
                project_id=proj["id"],
                duration_ms=dur,
                details={"url": url, "path": norm_target, "name": proj_name},
            )
            res["project"] = proj
        else:
            self.activity_store.log_operation(
                op_type="clone",
                status="failed",
                duration_ms=dur,
                details={"url": url, "path": norm_target},
                error_message=res.get("error"),
            )
        return res

    def _cmd_git_init(self, args: Dict[str, Any]) -> Any:
        path = args.get("path")
        proj_id = args.get("project_id")
        res = self.git_ops.init_repo(path, default_branch=args.get("default_branch", "main"))
        self.activity_store.log_operation(
            op_type="init",
            status="success" if res.get("success") else "failed",
            project_id=proj_id,
            details=res,
            error_message=res.get("error"),
        )
        return res

    def _cmd_git_status(self, args: Dict[str, Any]) -> Any:
        path = args.get("path")
        return self.repo_inspector.inspect(path)

    def _cmd_git_diff(self, args: Dict[str, Any]) -> Any:
        path = args.get("path")
        file_path = args.get("file_path")
        staged = bool(args.get("staged", False))
        return self.git_ops.get_file_diff(path, file_path, staged=staged)

    def _cmd_git_stage(self, args: Dict[str, Any]) -> Any:
        return self.git_ops.stage_file(args.get("path"), args.get("file_path"))

    def _cmd_git_unstage(self, args: Dict[str, Any]) -> Any:
        return self.git_ops.unstage_file(args.get("path"), args.get("file_path"))

    def _cmd_git_stage_all(self, args: Dict[str, Any]) -> Any:
        return self.git_ops.stage_all(args.get("path"))

    def _cmd_git_unstage_all(self, args: Dict[str, Any]) -> Any:
        return self.git_ops.unstage_all(args.get("path"))

    def _cmd_git_discard(self, args: Dict[str, Any]) -> Any:
        return self.git_ops.discard_file(args.get("path"), args.get("file_path"))

    def _cmd_git_commit(self, args: Dict[str, Any]) -> Any:
        path = args.get("path")
        proj_id = args.get("project_id")
        msg = args.get("message")
        t0 = time.time()
        res = self.git_ops.commit(path, msg)
        dur = int((time.time() - t0) * 1000)

        self.activity_store.log_operation(
            op_type="commit",
            status="success" if res.get("success") else "failed",
            project_id=proj_id,
            duration_ms=dur,
            details={"message": msg, "hash": res.get("commit_hash")},
            error_message=res.get("error"),
        )
        return res

    def _cmd_git_branches(self, args: Dict[str, Any]) -> Any:
        return self.git_ops.list_branches(args.get("path"))

    def _cmd_git_create_branch(self, args: Dict[str, Any]) -> Any:
        path = args.get("path")
        proj_id = args.get("project_id")
        name = args.get("name")
        checkout = bool(args.get("checkout", True))
        res = self.git_ops.create_branch(path, name, checkout=checkout)
        self.activity_store.log_operation(
            op_type="branch_create",
            status="success" if res.get("success") else "failed",
            project_id=proj_id,
            details={"branch": name, "checkout": checkout},
            error_message=res.get("error"),
        )
        return res

    def _cmd_git_switch_branch(self, args: Dict[str, Any]) -> Any:
        path = args.get("path")
        proj_id = args.get("project_id")
        name = args.get("name")
        res = self.git_ops.switch_branch(path, name)
        self.activity_store.log_operation(
            op_type="branch_switch",
            status="success" if res.get("success") else "failed",
            project_id=proj_id,
            details={"branch": name},
            error_message=res.get("error"),
        )
        return res

    def _cmd_git_delete_branch(self, args: Dict[str, Any]) -> Any:
        path = args.get("path")
        proj_id = args.get("project_id")
        name = args.get("name")
        force = bool(args.get("force", False))
        res = self.git_ops.delete_branch(path, name, force=force)
        self.activity_store.log_operation(
            op_type="branch_delete",
            status="success" if res.get("success") else "failed",
            project_id=proj_id,
            details={"branch": name, "force": force},
            error_message=res.get("error"),
        )
        return res

    def _cmd_git_fetch(self, args: Dict[str, Any]) -> Any:
        path = args.get("path")
        proj_id = args.get("project_id")
        remote = args.get("remote", "origin")
        t0 = time.time()
        res = self.git_ops.fetch(path, remote)
        dur = int((time.time() - t0) * 1000)

        self.activity_store.log_operation(
            op_type="fetch",
            status="success" if res.get("success") else "failed",
            project_id=proj_id,
            duration_ms=dur,
            details={"remote": remote},
            error_message=res.get("error"),
        )
        return res

    def _cmd_git_pull(self, args: Dict[str, Any]) -> Any:
        path = args.get("path")
        proj_id = args.get("project_id")
        remote = args.get("remote", "origin")
        branch = args.get("branch")
        t0 = time.time()
        res = self.git_ops.pull(path, remote, branch)
        dur = int((time.time() - t0) * 1000)

        self.activity_store.log_operation(
            op_type="pull",
            status="success" if res.get("success") else "failed",
            project_id=proj_id,
            duration_ms=dur,
            details={"remote": remote, "branch": branch, "is_conflict": res.get("is_conflict")},
            error_message=res.get("error"),
        )
        return res

    def _cmd_git_push(self, args: Dict[str, Any]) -> Any:
        path = args.get("path")
        proj_id = args.get("project_id")
        remote = args.get("remote", "origin")
        branch = args.get("branch")
        set_upstream = bool(args.get("set_upstream", False))
        t0 = time.time()
        res = self.git_ops.push(path, remote, branch, set_upstream)
        dur = int((time.time() - t0) * 1000)

        self.activity_store.log_operation(
            op_type="push",
            status="success" if res.get("success") else "failed",
            project_id=proj_id,
            duration_ms=dur,
            details={"remote": remote, "branch": branch},
            error_message=res.get("error"),
        )
        return res

    def _cmd_git_history(self, args: Dict[str, Any]) -> Any:
        path = args.get("path")
        limit = int(args.get("limit", 50))
        skip = int(args.get("skip", 0))
        branch = args.get("branch")
        return self.git_ops.get_commit_history(path, limit=limit, skip=skip, branch=branch)

    def _cmd_git_remotes(self, args: Dict[str, Any]) -> Any:
        path = args.get("path")
        info = self.repo_inspector.inspect(path)
        return info.get("remotes", [])

    def _cmd_git_add_remote(self, args: Dict[str, Any]) -> Any:
        return self.git_ops.add_remote(args.get("path"), args.get("name", "origin"), args.get("url"))

    def _cmd_git_set_remote_url(self, args: Dict[str, Any]) -> Any:
        return self.git_ops.set_remote_url(args.get("path"), args.get("name", "origin"), args.get("url"))

    # ==========================
    # GitHub Handlers
    # ==========================

    def _cmd_github_test_connection(self, args: Dict[str, Any]) -> Any:
        return self.github_client.test_connection()

    def _cmd_github_set_token(self, args: Dict[str, Any]) -> Any:
        token = args.get("token", "")
        success = self.keyring_auth.set_token(token)
        return {"success": success}

    def _cmd_github_delete_token(self, args: Dict[str, Any]) -> Any:
        return {"success": self.keyring_auth.delete_token()}

    def _cmd_github_has_token(self, args: Dict[str, Any]) -> Any:
        return {"has_token": self.keyring_auth.has_token()}

    def _cmd_github_list_repos(self, args: Dict[str, Any]) -> Any:
        return self.github_client.list_repositories()

    def _cmd_github_repositories(self, args: Dict[str, Any]) -> Any:
        """Returns GitHub repositories enriched with local cloned project status."""
        gh_res = self.github_client.list_repositories(per_page=100)
        if not gh_res.get("success"):
            return {"success": False, "error": gh_res.get("error"), "repositories": []}

        local_projects = self.project_store.list_projects()
        # Map remote URLs and project names to local project records
        local_by_remote = {}
        local_by_name = {}
        for p in local_projects:
            remote = (p.get("git_remote") or "").lower().rstrip("/").replace(".git", "")
            if remote:
                local_by_remote[remote] = p
            local_by_name[p["name"].lower()] = p

        base_projects_dir = os.path.join(os.path.expanduser("~"), "DevSyncProjects")
        enriched_repos = []

        for r in gh_res.get("repositories", []):
            clone_clean = r["clone_url"].lower().rstrip("/").replace(".git", "")
            html_clean = r["html_url"].lower().rstrip("/").replace(".git", "")
            matched_local = local_by_remote.get(clone_clean) or local_by_remote.get(html_clean) or local_by_name.get(r["name"].lower())

            rec_path = os.path.join(base_projects_dir, r["name"])

            if matched_local:
                info = self.repo_inspector.inspect(matched_local["local_path"])
                enriched_repos.append({
                    "name": r["name"],
                    "full_name": r["full_name"],
                    "html_url": r["html_url"],
                    "clone_url": r["clone_url"],
                    "private": r["private"],
                    "description": r["description"],
                    "stargazers_count": r["stargazers_count"],
                    "is_cloned": True,
                    "project_id": matched_local["id"],
                    "local_path": matched_local["local_path"],
                    "status": info.get("status", "Synced"),
                    "current_branch": info.get("current_branch", "main"),
                    "ahead": info.get("ahead", 0),
                    "behind": info.get("behind", 0),
                    "uncommitted_count": info.get("uncommitted_count", 0),
                })
            else:
                enriched_repos.append({
                    "name": r["name"],
                    "full_name": r["full_name"],
                    "html_url": r["html_url"],
                    "clone_url": r["clone_url"],
                    "private": r["private"],
                    "description": r["description"],
                    "stargazers_count": r["stargazers_count"],
                    "is_cloned": False,
                    "project_id": None,
                    "local_path": rec_path,
                    "status": "Remote on GitHub",
                    "current_branch": r["default_branch"],
                    "ahead": 0,
                    "behind": 0,
                    "uncommitted_count": 0,
                })

        return {
            "success": True,
            "repositories": enriched_repos,
            "total_remote": len(enriched_repos),
            "total_cloned": sum(1 for x in enriched_repos if x["is_cloned"]),
        }

    def _cmd_github_create_repo(self, args: Dict[str, Any]) -> Any:
        name = args.get("name", "")
        desc = args.get("description", "")
        private = bool(args.get("private", True))
        auto_init = bool(args.get("auto_init", False))
        gitignore = args.get("gitignore_template")
        license_tpl = args.get("license_template")
        return self.github_client.create_repository(name, desc, private, auto_init, gitignore, license_tpl)

    def _cmd_github_link_repo(self, args: Dict[str, Any]) -> Any:
        proj_id = args.get("project_id")
        remote_url = args.get("remote_url")
        proj = self.project_store.get_project(proj_id)
        if not proj:
            raise ValueError(f"Project '{proj_id}' not found.")

        path = proj["local_path"]
        # Check if origin already exists
        info = self.repo_inspector.inspect(path)
        existing_remotes = [r["name"] for r in info.get("remotes", [])]
        if "origin" in existing_remotes:
            res = self.git_ops.set_remote_url(path, "origin", remote_url)
        else:
            res = self.git_ops.add_remote(path, "origin", remote_url)

        if res.get("success"):
            self.project_store.update_project(proj_id, git_remote=remote_url)
        return res

    # ==========================
    # Reports & Activity Handlers
    # ==========================

    def _cmd_reports_get(self, args: Dict[str, Any]) -> Any:
        proj_id = args.get("project_id")
        proj = self.project_store.get_project(proj_id)
        if not proj:
            raise ValueError(f"Project '{proj_id}' not found.")
        return self.report_gen.generate(proj_id, proj["local_path"], proj.get("git_remote"))

    def _cmd_reports_export(self, args: Dict[str, Any]) -> Any:
        proj_id = args.get("project_id")
        fmt = args.get("format", "json").lower()
        output_path = args.get("output_path")
        report = self._cmd_reports_get({"project_id": proj_id})
        if fmt == "csv":
            ok = export_report_csv(report, output_path)
        else:
            ok = export_report_json(report, output_path)
        return {"success": ok, "path": output_path}

    def _cmd_activity_list(self, args: Dict[str, Any]) -> Any:
        proj_id = args.get("project_id")
        op_type = args.get("op_type")
        status = args.get("status")
        limit = int(args.get("limit", 100))
        offset = int(args.get("offset", 0))
        return self.activity_store.list_operations(proj_id, op_type, status, limit, offset)

    def _cmd_activity_export(self, args: Dict[str, Any]) -> Any:
        fmt = args.get("format", "json").lower()
        output_path = args.get("output_path")
        ops = self.activity_store.list_operations(limit=1000)
        if fmt == "csv":
            ok = export_activity_csv(ops, output_path)
        else:
            ok = export_activity_json(ops, output_path)
        return {"success": ok, "path": output_path}

    # ==========================
    # Settings & System Handlers
    # ==========================

    def _cmd_settings_get_all(self, args: Dict[str, Any]) -> Any:
        return self.settings_store.get_all()

    def _cmd_settings_set(self, args: Dict[str, Any]) -> Any:
        new_settings = args.get("settings", {})
        self.settings_store.set_multiple(new_settings)
        # Update git path or api url if modified
        if "git_path" in new_settings:
            try:
                self.git_cli.set_git_path(new_settings["git_path"])
            except Exception as e:
                logger.warning("Failed to update git path: %s", e)
        if "github_api_url" in new_settings:
            self.github_client.set_base_url(new_settings["github_api_url"])
        return self.settings_store.get_all()

    def _cmd_system_info(self, args: Dict[str, Any]) -> Any:
        import sys
        return {
            "app_name": "DevSync Studio",
            "version": "1.0.0",
            "git_version": self.git_cli.get_version(),
            "git_path": self.git_cli.git_path,
            "python_version": sys.version,
            "database_path": self.db.db_path,
        }
