"""
Project health report and metrics generator.
Produces actionable health diagnostics and commit activity trends based on real Git data.
"""

import datetime
from typing import Dict, Any, List, Optional
from ..git.cli import GitCLI
from ..git.repo_inspector import RepoInspector
from ..storage.activity_store import ActivityStore
from ..github.client import GitHubClient


class HealthReportGenerator:
    def __init__(
        self,
        cli: Optional[GitCLI] = None,
        inspector: Optional[RepoInspector] = None,
        activity_store: Optional[ActivityStore] = None,
        github_client: Optional[GitHubClient] = None,
    ):
        self.cli = cli or GitCLI()
        self.inspector = inspector or RepoInspector(self.cli)
        self.activity_store = activity_store
        self.github_client = github_client

    def generate(self, project_id: str, local_path: str, git_remote: Optional[str] = None) -> Dict[str, Any]:
        """Generates a comprehensive real health report for a project."""
        repo_info = self.inspector.inspect(local_path)

        if not repo_info.get("is_git_repo"):
            return {
                "project_id": project_id,
                "path": local_path,
                "is_git_repo": False,
                "health_score": 0,
                "grade": "N/A",
                "recommendations": [
                    "This folder is not a Git repository. Initialize Git to enable version control and tracking."
                ],
                "generated_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
            }

        # 1. Contributors count
        contributors = []
        contrib_res = self.cli.run(["shortlog", "-sne", "HEAD"], cwd=local_path)
        if contrib_res.ok and contrib_res.stdout:
            for line in contrib_res.stdout.splitlines():
                line = line.strip()
                if line:
                    parts = line.split("\t", 1)
                    if len(parts) == 2:
                        try:
                            c_count = int(parts[0].strip())
                            c_author = parts[1].strip()
                            contributors.append({"author": c_author, "commits": c_count})
                        except ValueError:
                            pass

        # 2. Activity Trends: Commit count per day for the last 14 days
        today = datetime.date.today()
        daily_activity: Dict[str, int] = {}
        for i in range(14):
            day_str = (today - datetime.timedelta(days=13 - i)).isoformat()
            daily_activity[day_str] = 0

        # Query git log dates for last 14 days
        since_date = (today - datetime.timedelta(days=14)).isoformat()
        log_dates_res = self.cli.run(
            ["log", f"--since={since_date}", "--format=%ad", "--date=short"],
            cwd=local_path,
        )
        if log_dates_res.ok and log_dates_res.stdout:
            for line in log_dates_res.stdout.splitlines():
                d_str = line.strip()
                if d_str in daily_activity:
                    daily_activity[d_str] += 1

        activity_chart = [{"date": k, "count": v} for k, v in daily_activity.items()]

        # 3. Last successful push & pull from ActivityStore
        last_sync = {"push": None, "pull": None, "fetch": None}
        if self.activity_store:
            last_sync = self.activity_store.get_last_sync_times(project_id)

        # 4. GitHub remote details if applicable
        github_data = None
        remote_url = repo_info.get("primary_remote_url") or git_remote or ""
        if self.github_client and "github.com" in remote_url.lower():
            # Extract owner/repo
            # e.g. git@github.com:owner/repo.git or https://github.com/owner/repo.git
            clean_url = remote_url.replace(".git", "").rstrip("/")
            if "github.com/" in clean_url:
                parts = clean_url.split("github.com/")[-1].split("/")
                if len(parts) >= 2:
                    owner, repo = parts[0], parts[1]
                    gh_res = self.github_client.get_repository(owner, repo)
                    if gh_res.get("success"):
                        github_data = gh_res.get("repository")

        # 5. Compute Health Score (0-100) & Actionable Recommendations
        score = 100
        recommendations: List[str] = []

        uncommitted = repo_info.get("uncommitted_count", 0)
        conflict = repo_info.get("conflict_count", 0)
        ahead = repo_info.get("ahead", 0)
        behind = repo_info.get("behind", 0)
        upstream = repo_info.get("upstream")

        if conflict > 0:
            score -= 40
            recommendations.append(f"Merge conflict detected in {conflict} file(s). Resolve conflicts before proceeding.")
        if uncommitted > 0:
            deduction = min(25, uncommitted * 3)
            score -= deduction
            recommendations.append(
                f"You have {uncommitted} uncommitted file(s). Review changes, stage them, and make a commit."
            )
        if behind > 0:
            score -= min(20, behind * 4)
            recommendations.append(
                f"Local branch is behind upstream by {behind} commit(s). Pull changes to avoid merge conflicts."
            )
        if ahead > 0:
            score -= min(15, ahead * 3)
            recommendations.append(
                f"Local branch has {ahead} unpushed commit(s). Push your work to keep remote synchronized."
            )
        if not upstream:
            score -= 15
            recommendations.append(
                "Branch has no tracked upstream branch. Configure tracking or push with '-u origin <branch>'."
            )

        score = max(0, min(100, score))

        if score >= 90:
            grade = "A+"
        elif score >= 80:
            grade = "A"
        elif score >= 70:
            grade = "B"
        elif score >= 50:
            grade = "C"
        else:
            grade = "Needs Attention"

        if not recommendations:
            recommendations.append("Repository is in excellent condition. Working tree is clean and synchronized.")

        return {
            "project_id": project_id,
            "path": local_path,
            "is_git_repo": True,
            "health_score": score,
            "grade": grade,
            "current_branch": repo_info.get("current_branch"),
            "upstream": upstream or "None",
            "total_commits": repo_info.get("total_commits", 0),
            "contributors_count": len(contributors),
            "contributors": contributors[:10],
            "uncommitted_count": uncommitted,
            "staged_count": repo_info.get("staged_count", 0),
            "modified_count": repo_info.get("modified_count", 0),
            "untracked_count": repo_info.get("untracked_count", 0),
            "conflict_count": conflict,
            "ahead": ahead,
            "behind": behind,
            "status": repo_info.get("status"),
            "last_commit": repo_info.get("last_commit"),
            "last_successful_push": last_sync.get("push"),
            "last_successful_pull": last_sync.get("pull"),
            "activity_chart": activity_chart,
            "github": github_data,
            "recommendations": recommendations,
            "generated_at": datetime.datetime.now(datetime.timezone.utc).isoformat(),
        }
