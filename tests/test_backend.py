"""
Unit and integration tests for DevSync Studio backend components.
Tests real Git commands on a temporary test repository, SQLite operations,
Keyring auth, GitHub API client, and Dispatcher.
"""

import os
import shutil
import tempfile
import pytest

from backend.git.cli import GitCLI, sanitize_text
from backend.git.repo_inspector import RepoInspector
from backend.git.operations import GitOperations
from backend.git.diff_parser import parse_diff
from backend.github.keyring_auth import KeyringAuth
from backend.github.client import GitHubClient
from backend.storage.db import Database
from backend.storage.project_store import ProjectStore
from backend.storage.activity_store import ActivityStore
from backend.storage.settings_store import SettingsStore
from backend.reports.health import HealthReportGenerator
from backend.dispatcher import Dispatcher


@pytest.fixture
def temp_dir():
    d = tempfile.mkdtemp(prefix="devsync_test_")
    yield d
    try:
        shutil.rmtree(d, ignore_errors=True)
    except Exception:
        pass


@pytest.fixture
def temp_db(temp_dir):
    db_path = os.path.join(temp_dir, "test_devsync.db")
    return Database(db_path)


def test_sanitize_text():
    raw = "Remote URL: https://ghp_abcdef1234567890@github.com/owner/repo.git"
    sanitized = sanitize_text(raw)
    assert "ghp_abcdef1234567890" not in sanitized
    assert "https://***@github.com" in sanitized


def test_git_cli_version():
    cli = GitCLI()
    version = cli.get_version()
    assert "git version" in version.lower()


def test_git_operations_lifecycle(temp_dir):
    cli = GitCLI()
    ops = GitOperations(cli)
    inspector = RepoInspector(cli)

    repo_path = os.path.join(temp_dir, "test_repo")
    os.makedirs(repo_path, exist_ok=True)

    # 1. Not a git repo initially
    assert not inspector.is_git_repo(repo_path)

    # 2. Init repo
    init_res = ops.init_repo(repo_path, default_branch="main")
    assert init_res["success"]
    assert inspector.is_git_repo(repo_path)

    # Configure user for commit
    cli.run(["config", "user.name", "DevSync Tester"], cwd=repo_path)
    cli.run(["config", "user.email", "tester@example.com"], cwd=repo_path)

    # 3. Create a test file
    test_file = os.path.join(repo_path, "README.md")
    with open(test_file, "w") as f:
        f.write("# Test Project\nInitial line\n")

    # 4. Check status shows untracked file
    status = inspector.inspect(repo_path)
    assert status["untracked_count"] == 1
    assert status["status"] in ("Initial (Empty)", "Modified")

    # 5. Stage file
    stage_res = ops.stage_file(repo_path, "README.md")
    assert stage_res["success"]

    # 6. Commit
    commit_res = ops.commit(repo_path, "Initial commit")
    assert commit_res["success"]
    assert commit_res["commit_hash"]

    # 7. Inspector after commit
    status2 = inspector.inspect(repo_path)
    assert status2["has_commits"]
    assert status2["total_commits"] == 1
    assert status2["last_commit"]["message"] == "Initial commit"
    assert status2["uncommitted_count"] == 0

    # 8. Modify file and check diff
    with open(test_file, "a") as f:
        f.write("Second line added\n")

    diff_res = ops.get_file_diff(repo_path, "README.md")
    assert diff_res["success"]
    assert len(diff_res["files"]) > 0
    assert diff_res["files"][0]["status"] == "modified"

    # 9. Branching
    b_res = ops.create_branch(repo_path, "feature-1", checkout=True)
    assert b_res["success"]
    branches = ops.list_branches(repo_path)
    b_names = [b["name"] for b in branches["local"]]
    assert "feature-1" in b_names

    # 10. Switch branch
    sw_res = ops.switch_branch(repo_path, "main")
    assert sw_res["success"]

    # 11. Protect current branch against deletion
    del_active = ops.delete_branch(repo_path, "main")
    assert not del_active["success"]
    assert "currently checked out" in del_active["error"]

    # Delete inactive feature branch
    del_res = ops.delete_branch(repo_path, "feature-1", force=True)
    assert del_res["success"]


def test_storage_project_and_activity(temp_db, temp_dir):
    p_store = ProjectStore(temp_db)
    a_store = ActivityStore(temp_db)
    s_store = SettingsStore(temp_db)

    # Test settings
    s_store.set("theme", "dark")
    assert s_store.get("theme") == "dark"

    # Test project CRUD
    proj_path = os.path.join(temp_dir, "my_project")
    os.makedirs(proj_path, exist_ok=True)

    proj = p_store.add_project("My Project", proj_path)
    assert proj["id"]
    assert proj["name"] == "My Project"

    # Duplicate detection
    with pytest.raises(ValueError):
        p_store.add_project("Duplicate", proj_path)

    # Pinning
    p_store.set_pinned(proj["id"], True)
    fetched = p_store.get_project(proj["id"])
    assert fetched["is_pinned"] == 1

    # Activity logging
    op_id = a_store.log_operation(
        op_type="commit",
        status="success",
        project_id=proj["id"],
        duration_ms=120,
        details={"message": "feat: test"},
    )
    assert op_id

    ops = a_store.list_operations(project_id=proj["id"])
    assert len(ops) == 1
    assert ops[0]["op_type"] == "commit"
    assert ops[0]["status"] == "success"


def test_health_report(temp_dir, temp_db):
    cli = GitCLI()
    ops = GitOperations(cli)
    repo_path = os.path.join(temp_dir, "health_repo")
    os.makedirs(repo_path, exist_ok=True)
    ops.init_repo(repo_path)

    cli.run(["config", "user.name", "Tester"], cwd=repo_path)
    cli.run(["config", "user.email", "tester@test.com"], cwd=repo_path)

    fpath = os.path.join(repo_path, "file.txt")
    with open(fpath, "w") as f:
        f.write("content")
    ops.stage_all(repo_path)
    ops.commit(repo_path, "First commit")

    p_store = ProjectStore(temp_db)
    a_store = ActivityStore(temp_db)
    proj = p_store.add_project("Health Repo", repo_path)

    report_gen = HealthReportGenerator(cli=cli, activity_store=a_store)
    report = report_gen.generate(proj["id"], repo_path)

    assert report["is_git_repo"]
    assert report["total_commits"] == 1
    assert report["health_score"] > 70
    assert report["grade"] in ("A+", "A", "B")
    assert len(report["recommendations"]) > 0


def test_dispatcher(temp_dir, temp_db):
    disp = Dispatcher(temp_db.db_path)

    # Add project via dispatcher
    proj_dir = os.path.join(temp_dir, "disp_proj")
    os.makedirs(proj_dir, exist_ok=True)

    proj = disp.dispatch("projects.add", {"path": proj_dir, "name": "Dispatcher Proj"})
    assert proj["id"]

    # Git init via dispatcher
    init_res = disp.dispatch("git.init", {"path": proj_dir, "project_id": proj["id"]})
    assert init_res["success"]

    # System info
    sys_info = disp.dispatch("system.info", {})
    assert sys_info["app_name"] == "DevSync Studio"
    assert "git version" in sys_info["git_version"].lower()


def test_upload_to_github_validation(temp_dir, temp_db):
    disp = Dispatcher(temp_db.db_path)
    disp.keyring_auth.get_token = lambda: None
    proj_dir = os.path.join(temp_dir, "upload_proj")
    os.makedirs(proj_dir, exist_ok=True)
    proj = disp.dispatch("projects.add", {"path": proj_dir, "name": "Upload Proj"})

    # Should raise error when no token configured
    with pytest.raises(ValueError, match="No GitHub token"):
        disp.dispatch("projects.upload_to_github", {"project_id": proj["id"]})


def test_studio_file_operations(temp_dir, temp_db):
    disp = Dispatcher(temp_db.db_path)
    proj_dir = os.path.join(temp_dir, "studio_proj")
    os.makedirs(proj_dir, exist_ok=True)
    proj = disp.dispatch("projects.add", {"path": proj_dir, "name": "Studio Proj"})

    # Create file
    create_res = disp.dispatch("files.create_file", {"proj_path": proj_dir, "rel_path": "main.py"})
    assert create_res["success"]

    # Write file
    write_res = disp.dispatch("files.write_file", {"path": os.path.join(proj_dir, "main.py"), "content": "print('hello studio')"})
    assert write_res["success"]

    # Read file
    read_res = disp.dispatch("files.read_file", {"path": os.path.join(proj_dir, "main.py")})
    assert read_res["success"]
    assert "hello studio" in read_res["content"]

    # List tree
    tree_res = disp.dispatch("files.list_tree", {"path": proj_dir})
    assert tree_res["success"]
    assert any(i["name"] == "main.py" for i in tree_res["items"])


