# DevSync Studio — Professional GitHub Project Manager Desktop Application

**DevSync Studio** is a production-oriented desktop application architected with **C++ / Qt 6 (QML)** on the frontend and an asynchronous **Python** worker backend. It provides a central, developer-focused interface to manage all your local projects, Git operations, and GitHub repositories with high reliability, security, and real metrics.

---

## Architecture Overview

```
                                      DevSync Studio Desktop Application
┌────────────────────────────────────────────────────────────────────────────────────────────────────────┐
│                                                                                                        │
│   Frontend: Native C++20 / Qt 6.8 & QML                                                                │
│   ┌─────────────────────────────┐   ┌─────────────────────────────┐   ┌────────────────────────────┐   │
│   │  ThemeManager (Dark/Light)  │   │     Project & File Models   │   │  Views: Dashboard, Repos,  │   │
│   │                             │   │  (Fast QAbstractListModel)  │   │  Branches, Changes, Detail │   │
│   └──────────────┬──────────────┘   └──────────────┬──────────────┘   └─────────────┬──────────────┘   │
│                  │                                 │                                │                  │
│                  └─────────────────────────────────┼────────────────────────────────┘                  │
│                                                    ▼                                                   │
│                                        BackendBridge (QProcess)                                        │
│                                                    ▲                                                   │
└────────────────────────────────────────────────────┼───────────────────────────────────────────────────┘
                                                     │ Line-delimited JSON IPC over stdin / stdout
                                                     │ (Diagnostic logs strictly to stderr)
┌────────────────────────────────────────────────────┼───────────────────────────────────────────────────┐
│                                                    ▼                                                   │
│   Backend: Python 3 Worker Process                                                                     │
│   ┌─────────────────────────────┐   ┌─────────────────────────────┐   ┌────────────────────────────┐   │
│   │        Dispatcher &         │   │      Git Operations &       │   │    GitHub REST API Client  │   │
│   │     ThreadPoolExecutor      │   │     Porcelain Inspector     │   │   (OAuth/PAT, Rate Limits) │   │
│   └──────────────┬──────────────┘   └──────────────┬──────────────┘   └─────────────┬──────────────┘   │
│                  │                                 │                                │                  │
│                  └─────────────────────────────────┼────────────────────────────────┘                  │
│                                                    ▼                                                   │
│                                    SQLite Storage & OS Keyring Store                                   │
│                        (Projects, Activity Logs, Settings, Windows Vault PAT)                          │
└────────────────────────────────────────────────────────────────────────────────────────────────────────┘
```

---

## Key Features

1. **Main Dashboard**:
   - Live summary metrics: Total Projects, Git Repositories, GitHub-connected Repositories, Uncommitted Changes, Pending Pushes (ahead), Pending Pulls (behind), and Sync Errors/Conflicts.
   - Filterable, searchable Project Overview with quick actions: Open Folder, View Changes, Commit, Push, Pull, Create Branch, and View Health Report.

2. **Project Details & Deep Health Reports**:
   - **Overview**: Local path, remote details, current branch, working-tree breakdown, tracking status.
   - **Health Report**: Calculated 0–100 health score with letter grade, 14-day commit activity trend visualization, contributors list, actionable recommendations, and export to CSV or JSON.
   - **Changes & Diffs**: Stage/unstage individual files or all, discard changes with confirmation protection, unified diff viewer with addition/deletion line highlighting, and commit/push forms.
   - **Commits**: Paginated commit history with commit hashes, authors, timestamps, and subjects.
   - **Branches**: Local and remote branch lists, current branch indicator, branch creation, branch switching, and safe branch deletion (with current branch protection).
   - **Remote**: Remote URL management, connection testing, and linking to GitHub.

3. **Projects Management**:
   - Native folder picker (`QFileDialog`).
   - Automatic Git repository detection.
   - Safe Git initialization in selected non-Git folders.
   - Safe removal of projects from the app metadata without deleting local files.
   - Project pinning and duplicate path detection.

4. **Repositories Management**:
   - Clear distinction between `fetch`, `pull`, and `push`.
   - Direct link to open repositories on GitHub.com.
   - Sync status indicator and conflict reporting.

5. **Branch Manager**:
   - List local and remote branches.
   - Switch branches safely with uncommitted work detection.
   - Safe deletion preventing accidental deletion of the checked-out branch.

6. **Activity & Audit Log**:
   - Full history of all push, pull, fetch, commit, and branch actions with timestamps and durations.
   - Filter by status (All, Success, Failed) and export logs to CSV and JSON.

7. **GitHub Integration & OS Keyring Security**:
   - Connect Personal Access Tokens securely stored in the **Windows Credential Manager (WinVault)** using `keyring`.
   - **Zero plaintext secrets**: Tokens are never stored in SQLite, config files, source code, or logs.
   - Token testing, rate-limit meters, and remote repository browser.
   - Create new remote repositories on GitHub directly from the app.

8. **Settings & Customization**:
   - Real-time dark and light theme switching.
   - Git executable detection and custom path selection.
   - GitHub API base URL configuration (GitHub Enterprise support).
   - Configurable background auto-refresh interval.

---

## Directory Structure

```
d:\Github Automation\
├── CMakeLists.txt                # CMake build configuration for Qt 6 & MSVC
├── qml.qrc                       # Qt compiled resource file for QML
├── README.md                     # Documentation and setup guide
├── app/
│   └── main.cpp                  # C++ entry point, QApplication & QML engine setup
├── cpp/
│   ├── BackendBridge.h/.cpp      # QProcess IPC manager with Python worker
│   ├── ProjectModel.h/.cpp       # Reactive QAbstractListModel for project cards
│   ├── ActivityModel.h/.cpp      # Reactive QAbstractListModel for activity log
│   ├── FileStatusModel.h/.cpp    # Reactive model for staged/modified/untracked files
│   └── ThemeManager.h/.cpp       # Dynamic Dark/Light theme palette system
├── ui/
│   ├── Main.qml                  # Root application window, navigation & dialogs
│   ├── components/
│   │   ├── ActionButton.qml      # Styled button (primary, secondary, danger, subtle)
│   │   ├── ConfirmDialog.qml     # Destructive action modal confirmation
│   │   ├── DiffViewer.qml        # Unified diff viewer with addition/deletion styling
│   │   ├── ProjectCard.qml       # Dashboard project row with quick actions
│   │   ├── Sidebar.qml           # Primary left navigation sidebar
│   │   ├── StatCard.qml          # Dashboard summary metric card
│   │   ├── StatusBadge.qml       # Colored status pill (Synced, Modified, etc.)
│   │   ├── TextInputDialog.qml   # Modal for branch names, commit messages, URLs
│   │   ├── Toast.qml             # Non-intrusive floating notification toast
│   │   └── TopBar.qml            # Header with search, GitHub pill, theme toggle
│   └── views/
│       ├── DashboardView.qml     # Main overview with summary cards & project list
│       ├── ProjectsView.qml      # Folder picker, git init, project pinning
│       ├── RepositoriesView.qml  # Dedicated remote repository manager
│       ├── BranchesView.qml      # Local & remote branch manager
│       ├── ChangesView.qml       # Diff viewer, staging checkboxes, commit form
│       ├── ActivityView.qml      # Operations history and CSV/JSON export
│       ├── GitHubView.qml        # GitHub authentication & remote repository list
│       ├── SettingsView.qml      # Theme, Git path, GitHub API endpoint settings
│       └── ProjectDetailView.qml # Contextual subtabs (Overview, Report, Diff, Commits)
├── backend/
│   ├── server.py                 # Stdio JSON protocol listener & thread pool
│   ├── dispatcher.py             # Command router connecting IPC to handlers
│   ├── git/
│   │   ├── cli.py                # Safe subprocess Git execution (no shell=True)
│   │   ├── repo_inspector.py     # Authoritative repository state inspector
│   │   ├── operations.py         # Git commit, branch, diff, push, pull, fetch
│   │   └── diff_parser.py        # Unified diff parser into hunks and line types
│   ├── github/
│   │   ├── keyring_auth.py       # OS Secure Credential Store (Windows Credential Vault)
│   │   └── client.py             # GitHub REST API client & rate limiting
│   ├── storage/
│   │   ├── db.py                 # SQLite connection manager with WAL mode
│   │   ├── schema.py             # Versioned schema migrations
│   │   ├── project_store.py      # Project metadata repository
│   │   ├── activity_store.py     # Operations logging and query engine
│   │   └── settings_store.py     # Non-sensitive user preferences storage
│   ├── reports/
│   │   └── health.py             # Real metrics generator & 14-day activity chart
│   └── exporter/
│       └── report_export.py      # CSV and JSON report and activity log exporters
├── tests/
│   ├── test_backend.py           # Unit & integration tests for Git, DB, and Reports
│   └── test_server_protocol.py   # IPC protocol and JSON line exchange test
└── scripts/
    ├── build.bat                 # MSVC + CMake + Ninja build script
    ├── run.bat                   # Launch script for DevSync Studio
    ├── test.bat                  # Pytest execution script
    ├── package.bat               # windeployqt packaging script for distribution
    └── verify_app.py             # Automated startup & process stability verifier
```

---

## Prerequisites & Dependencies

- **Operating System:** Windows 10 / 11 (x64)
- **C++ Compiler:** MSVC 2022 / 2026 (v143 / v144) with C++20 support
- **Qt 6 Framework:** Qt 6.8+ (MSVC 2022 64-bit) with `Core`, `Gui`, `Qml`, `Quick`, `QuickControls2`, `Widgets`
- **Build Tools:** CMake 3.20+ and Ninja 1.10+
- **Git:** Git 2.x CLI installed on system `PATH`
- **Python:** Python 3.10+ (tested on Python 3.14) with:
  - `requests`
  - `keyring` (integrates natively with Windows Credential Vault)
  - `pytest`

---

## Build & Launch Instructions

### 1. Build the C++ / Qt Application
Run the build script from the project root:
```cmd
scripts\build.bat
```
This script initializes the MSVC x64 developer environment, configures CMake with Ninja, compiles the QML resources, and produces `build\DevSyncStudio.exe`.

### 2. Run the Application
To run the application:
```cmd
scripts\run.bat
```

### 3. Run Backend Tests
Run the automated pytest test suite:
```cmd
scripts\test.bat
```
Or directly:
```cmd
python -m pytest tests/ -v
```

### 4. Package for Desktop Distribution
To assemble a self-contained release folder with all Qt runtime DLLs, plugins, and backend modules:
```cmd
scripts\package.bat
```
The output directory will be created at:
```
dist\DevSyncStudio\
├── DevSyncStudio.exe
├── backend\
├── Qt6Core.dll, Qt6Gui.dll, Qt6Qml.dll, Qt6Quick.dll, etc.
└── qml\ and plugins\
```

---

## Security Architecture

- **Operating System Credential Vault:** GitHub personal access tokens are stored directly in the Windows Credential Manager via the `keyring` library under the service name `DevSyncStudio_GitHub`.
- **Zero Plaintext Storage:** Personal Access Tokens are **never** written to SQLite databases, JSON setting files, logs, or command-line parameters.
- **Git Credential Masking:** All command strings and output logging use `sanitize_text()`, which regex-strips tokens from remote URLs (e.g. `https://***@github.com`).
- **Safe Subprocess Execution:** Git commands are invoked as argument lists without `shell=True` to prevent argument injection vulnerabilities.
- **Destructive Operations Confirmation:** Destructive operations like discarding local changes or deleting branches require explicit confirmation dialogs and protect against deleting the currently checked-out branch.
