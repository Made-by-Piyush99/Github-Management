import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"
import "views"

ApplicationWindow {
    id: appWindow

    visible: true
    width: 1280
    height: 820
    minimumWidth: 1024
    minimumHeight: 680
    title: "DevSync Studio — GitHub Project Manager"

    color: themeManager.bgPrimary

    // 0: Dashboard, 1: Projects, 2: Repos, 3: Branches, 4: Changes, 5: Activity, 6: GitHub, 7: Guide & Info, 8: Settings, 9: Project Details
    property int activeTab: 0
    property string activeDetailProjectId: ""
    property string searchQuery: ""
    property var githubUser: null
    property bool isRefreshing: false

    function refreshAll() {
        isRefreshing = true;
        backendBridge.sendRequest("projects.list", {}, function(success, data, err) {
            isRefreshing = false;
            if (success) {
                projectModel.setProjects(data || []);
            } else {
                toast.show("Failed to refresh projects: " + err, "error");
            }
        });

        backendBridge.sendRequest("github.test_connection", {}, function(success, data) {
            if (success && data && data.connected) {
                appWindow.githubUser = data.user;
            } else {
                appWindow.githubUser = null;
            }
        });
    }

    function openProjectDetails(pId) {
        activeDetailProjectId = pId;
        activeTab = 9; // Project detail view
    }

    function openCreateRepoDialog() {
        var owner = appWindow.githubUser ? appWindow.githubUser.login : "owner";
        createRepoDialog.open(owner);
    }

    function checkTourOnStartup() {
        backendBridge.sendRequest("settings.get_all", {}, function(success, data) {
            if (success && data) {
                if (!data.tour_completed) {
                    appTourDialog.open();
                }
            }
        });
    }

    // Auto-refresh timer (default 30 seconds)
    Timer {
        id: autoRefreshTimer
        interval: 30000
        repeat: true
        running: true
        onTriggered: appWindow.refreshAll()
    }

    // Connect bridge signals
    Connections {
        target: backendBridge
        function onReadyReceived() {
            toast.show("Connected to DevSync backend.", "success");
            appWindow.refreshAll();
            appWindow.checkTourOnStartup();
        }
        function onTaskProgress(taskId, percent, msg) {
            toast.show(msg, "info");
        }
    }

    Component.onCompleted: {
        if (backendBridge.isConnected) {
            appWindow.refreshAll();
            appWindow.checkTourOnStartup();
        }
    }

    // Keyboard Shortcuts
    Shortcut {
        sequence: "Ctrl+R"
        onActivated: appWindow.refreshAll()
    }

    // Main App Layout: Sidebar on Left, Content on Right
    RowLayout {
        anchors.fill: parent
        spacing: 0

        // Sidebar
        Sidebar {
            id: sidebar
            Layout.fillHeight: true
            activeTab: appWindow.activeTab === 9 ? 0 : appWindow.activeTab
            gitVersion: "Git 2.x"
            backendConnected: backendBridge.isConnected
            onTabSelected: function(idx) {
                appWindow.activeTab = idx;
            }
        }

        // Main Content Area
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // Top Bar
            TopBar {
                id: topBar
                Layout.fillWidth: true
                title: {
                    if (appWindow.activeTab === 0) return "Dashboard";
                    if (appWindow.activeTab === 1) return "Projects";
                    if (appWindow.activeTab === 2) return "Repositories";
                    if (appWindow.activeTab === 3) return "Branches";
                    if (appWindow.activeTab === 4) return "Changes & Commits";
                    if (appWindow.activeTab === 5) return "Activity & Reports";
                    if (appWindow.activeTab === 6) return "GitHub Integration";
                    if (appWindow.activeTab === 7) return "Guide & Info";
                    if (appWindow.activeTab === 8) return "Settings";
                    if (appWindow.activeTab === 9) return "Project Details";
                    return "DevSync Studio";
                }
                githubUser: appWindow.githubUser
                isRefreshing: appWindow.isRefreshing
                onSearchChanged: function(q) {
                    appWindow.searchQuery = q;
                }
                onRefreshClicked: appWindow.refreshAll()
                onGithubPillClicked: appWindow.activeTab = 6
                onCreateRepoClicked: appWindow.openCreateRepoDialog()
            }

            // Central Views Stack
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: appWindow.activeTab

                // 0: Dashboard
                DashboardView {
                    filterText: appWindow.searchQuery
                    onOpenProjectDetails: function(pId) {
                        appWindow.openProjectDetails(pId);
                    }
                    onRequestQuickAction: function(act, proj) {
                        if (act === "create_repo") {
                            appWindow.openCreateRepoDialog();
                        } else if (act === "refresh_all") {
                            appWindow.refreshAll();
                        } else if (act === "folder") {
                            backendBridge.openFolder(proj.local_path);
                        } else if (act === "changes") {
                            appWindow.openProjectDetails(proj.id);
                        } else if (act === "report") {
                            appWindow.openProjectDetails(proj.id);
                        } else if (act === "pull") {
                            toast.show("Pulling changes...", "info");
                            backendBridge.sendRequest("git.pull", {"path": proj.local_path, "project_id": proj.id}, function(s, d, err) {
                                if (s) { toast.show("Pull completed.", "success"); appWindow.refreshAll(); }
                                else toast.show("Pull failed: " + err, "error");
                            });
                        } else if (act === "push") {
                            toast.show("Pushing changes...", "info");
                            backendBridge.sendRequest("git.push", {"path": proj.local_path, "project_id": proj.id}, function(s, d, err) {
                                if (s) { toast.show("Push completed.", "success"); appWindow.refreshAll(); }
                                else toast.show("Push failed: " + err, "error");
                            });
                        } else if (act === "branch") {
                            appWindow.activeTab = 3;
                        } else if (act === "add_project") {
                            var folder = backendBridge.selectFolder("Select Project Folder", "");
                            if (folder) {
                                backendBridge.sendRequest("projects.add", {"path": folder}, function(s, d, err) {
                                    if (s) { toast.show("Project added!", "success"); appWindow.refreshAll(); }
                                    else toast.show("Error adding project: " + err, "error");
                                });
                            }
                        }
                    }
                }

                // 1: Projects
                ProjectsView {
                    filterQuery: appWindow.searchQuery
                    onOpenProject: function(pId) {
                        appWindow.openProjectDetails(pId);
                    }
                    onRefreshRequested: appWindow.refreshAll()
                }

                // 2: Repositories
                RepositoriesView {
                    filterText: appWindow.searchQuery
                    onOpenProject: function(pId) {
                        appWindow.openProjectDetails(pId);
                    }
                    onRefreshRequested: appWindow.refreshAll()
                }

                // 3: Branches
                BranchesView {
                    onRefreshRequested: appWindow.refreshAll()
                }

                // 4: Changes & Commits
                ChangesView {
                    onRefreshRequested: appWindow.refreshAll()
                }

                // 5: Activity & Reports
                ActivityView {
                    onRefreshRequested: appWindow.refreshAll()
                }

                // 6: GitHub Integration
                GitHubView {
                    onGithubStatusChanged: appWindow.refreshAll()
                }

                // 7: Guide & Info
                InfoView {
                    onRequestAppTour: function() {
                        appTourDialog.open();
                    }
                    onNavigateToTab: function(tabIndex) {
                        appWindow.activeTab = tabIndex;
                    }
                }

                // 8: Settings
                SettingsView {}

                // 9: Project Details Sub-page
                ProjectDetailView {
                    projectId: appWindow.activeDetailProjectId
                    onBackRequested: appWindow.activeTab = 0
                    onRefreshRequested: appWindow.refreshAll()
                }
            }
        }
    }

    // Modern GitHub-like Create Repository Dialog
    CreateRepoDialog {
        id: createRepoDialog
        onRepositoryCreated: function(repo) {
            toast.show("Created repository: " + repo.full_name, "success");
            appWindow.refreshAll();
            // Prompt to clone locally
            confirmDialog.open(
                "Repository Created",
                "Repository '" + repo.name + "' has been created on GitHub!\nWould you like to clone it into your local workspace now?",
                function() {
                    var target = "D:/DevSyncProjects/" + repo.name;
                    toast.show("Cloning " + repo.name + "...", "info");
                    backendBridge.sendRequest("git.clone", {"url": repo.clone_url, "target_dir": target, "name": repo.name}, function(s, d, err) {
                        if (s) {
                            toast.show("Cloned " + repo.name + " into workspace!", "success");
                            appWindow.refreshAll();
                            appWindow.activeTab = 0; // Go to dashboard
                        } else {
                            toast.show("Clone failed: " + err, "error");
                        }
                    });
                },
                "primary",
                "Clone to Workspace"
            );
        }
    }

    // App Onboarding Tour Dialog (with Skip option)
    AppTourDialog {
        id: appTourDialog
        onTourCompleted: toast.show("Tour completed! Enjoy using DevSync Studio.", "success")
        onTourSkipped: toast.show("Tour skipped. You can reopen it anytime from Guide & Info.", "info")
    }

    // Global Modal Confirmation Dialog
    ConfirmDialog {
        id: confirmDialog
    }

    // Global Text Input Dialog
    TextInputDialog {
        id: textInputDialog
    }

    // Global Floating Toast Notification
    Toast {
        id: toast
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
    }
}
