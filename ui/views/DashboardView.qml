import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

ScrollView {
    id: root

    property string filterText: ""
    property var githubUser: null
    property var githubRepos: []
    property int githubRemoteCount: 0

    signal openProjectDetails(string projectId)
    signal requestQuickAction(string action, var project)

    contentWidth: availableWidth
    clip: true

    // Computed metrics from projectModel
    property int totalProjects: projectModel.count
    property int gitReposCount: 0
    property int githubReposCount: 0
    property int uncommittedCount: 0
    property int pendingPushesCount: 0
    property int pendingPullsCount: 0
    property int syncErrorsCount: 0

    function loadGitHubRepos() {
        backendBridge.sendRequest("github.repositories", {}, function(success, data, err) {
            if (success && data && data.repositories) {
                githubRepos = data.repositories;
                githubRemoteCount = data.repositories.length;
                updateMetrics();
            }
        });
    }

    function updateMetrics() {
        var gitCount = 0;
        var ghLinkedCount = 0;
        var uncomm = 0;
        var pushes = 0;
        var pulls = 0;
        var errors = 0;

        for (var i = 0; i < projectModel.count; ++i) {
            var p = projectModel.get(i);
            if (p.is_git_repo) gitCount++;
            if (p.has_github_remote) ghLinkedCount++;
            if ((p.uncommitted_count || 0) > 0) uncomm++;
            if ((p.ahead || 0) > 0) pushes++;
            if ((p.behind || 0) > 0) pulls++;
            var st = (p.status || "").toLowerCase();
            if (st.indexOf("conflict") !== -1 || st.indexOf("error") !== -1) errors++;
        }

        gitReposCount = gitCount;
        // If GitHub account is connected, show total remote repos or linked repos
        githubReposCount = Math.max(ghLinkedCount, root.githubRemoteCount);
        uncommittedCount = uncomm;
        pendingPushesCount = pushes;
        pendingPullsCount = pulls;
        syncErrorsCount = errors;
    }

    Connections {
        target: projectModel
        function onCountChanged() {
            root.updateMetrics();
            root.loadGitHubRepos();
        }
    }

    Component.onCompleted: {
        loadGitHubRepos();
        updateMetrics();
    }

    ColumnLayout {
        width: parent.width
        anchors.margins: 24
        spacing: 24

        // Top Summary Metric Cards Grid
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                Text {
                    text: "WORKSPACE SUMMARY"
                    color: themeManager.textMuted
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                Item { Layout.fillWidth: true }

                ActionButton {
                    text: "Create New Repository"
                    iconName: "plus"
                    btnStyle: "primary"
                    small: true
                    onClicked: root.requestQuickAction("create_repo", null)
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: 4
                rowSpacing: 12
                columnSpacing: 12

                StatCard {
                    Layout.fillWidth: true
                    title: "Total Projects"
                    value: "" + root.totalProjects
                    subtext: "Tracked in workspace"
                    iconName: "project"
                    highlightColor: themeManager.accent
                }

                StatCard {
                    Layout.fillWidth: true
                    title: "Git Repositories"
                    value: "" + root.gitReposCount
                    subtext: "Active local repositories"
                    iconName: "branch"
                    highlightColor: themeManager.success
                }

                StatCard {
                    Layout.fillWidth: true
                    title: "GitHub Repositories"
                    value: "" + root.githubReposCount
                    subtext: root.githubRemoteCount > 0 ? (root.githubRemoteCount + " on connected account") : "Linked to remote"
                    iconName: "github"
                    highlightColor: themeManager.info
                }

                StatCard {
                    Layout.fillWidth: true
                    title: "Uncommitted Changes"
                    value: "" + root.uncommittedCount
                    subtext: "Require commit / review"
                    iconName: "diff"
                    highlightColor: themeManager.warning
                    isWarning: root.uncommittedCount > 0
                }

                StatCard {
                    Layout.fillWidth: true
                    title: "Pending Pushes"
                    value: "" + root.pendingPushesCount
                    subtext: "Ahead of remote"
                    iconName: "push"
                    highlightColor: themeManager.accent
                }

                StatCard {
                    Layout.fillWidth: true
                    title: "Pending Pulls"
                    value: "" + root.pendingPullsCount
                    subtext: "Behind remote"
                    iconName: "pull"
                    highlightColor: themeManager.warning
                }

                StatCard {
                    Layout.fillWidth: true
                    title: "Sync Errors & Conflicts"
                    value: "" + root.syncErrorsCount
                    subtext: root.syncErrorsCount === 0 ? "All remotes healthy" : "Requires resolution"
                    iconName: "shield"
                    highlightColor: themeManager.danger
                    isWarning: root.syncErrorsCount > 0
                }

                StatCard {
                    Layout.fillWidth: true
                    title: "Synchronization Status"
                    value: root.syncErrorsCount > 0 ? "Issues" : "Healthy"
                    subtext: "Verified local & remote"
                    iconName: "refresh"
                    highlightColor: root.syncErrorsCount > 0 ? themeManager.danger : themeManager.success
                }
            }
        }

        // Projects Section Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: "PROJECT OVERVIEW"
                color: themeManager.textMuted
                font.pixelSize: 11
                font.weight: Font.Bold
            }

            Item { Layout.fillWidth: true }

            Text {
                text: "Showing " + projectModel.count + " project(s)"
                color: themeManager.textMuted
                font.pixelSize: 12
            }
        }

        // Local Projects List
        ListView {
            visible: projectModel.count > 0
            Layout.fillWidth: true
            implicitHeight: contentHeight
            interactive: false
            spacing: 12
            model: projectModel

            delegate: ProjectCard {
                width: ListView.view.width
                projectData: projectModel.get(index)

                visible: {
                    if (!root.filterText) return true;
                    var q = root.filterText.toLowerCase();
                    var nameMatch = (projectData.name || "").toLowerCase().indexOf(q) !== -1;
                    var pathMatch = (projectData.local_path || "").toLowerCase().indexOf(q) !== -1;
                    var branchMatch = (projectData.current_branch || "").toLowerCase().indexOf(q) !== -1;
                    return nameMatch || pathMatch || branchMatch;
                }

                onOpenDetails: function(pId) {
                    root.openProjectDetails(pId);
                }

                onQuickAction: function(act, proj) {
                    root.requestQuickAction(act, proj);
                }
            }
        }

        // Connected GitHub Repositories Section (Shows when GitHub is connected!)
        ColumnLayout {
            visible: root.githubRepos.length > 0
            Layout.fillWidth: true
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: "GITHUB REPOSITORIES ON YOUR ACCOUNT (" + root.githubRepos.length + ")"
                    color: themeManager.textMuted
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                Item { Layout.fillWidth: true }

                ActionButton {
                    text: "Clone All to Workspace"
                    iconName: "pull"
                    btnStyle: "primary"
                    small: true
                    onClicked: {
                        var uncloned = root.githubRepos.filter(function(r) { return !r.is_cloned; });
                        if (uncloned.length === 0) {
                            toast.show("All repositories are already cloned!", "info");
                            return;
                        }
                        toast.show("Starting clone of " + uncloned.length + " repositories...", "info");
                        var cloneNext = function(idx) {
                            if (idx >= uncloned.length) {
                                toast.show("Finished cloning repositories!", "success");
                                root.loadGitHubRepos();
                                root.requestQuickAction("refresh_all", null);
                                return;
                            }
                            var r = uncloned[idx];
                            var target = "D:/DevSyncProjects/" + r.name;
                            backendBridge.sendRequest("git.clone", {"url": r.clone_url, "target_dir": target, "name": r.name}, function() {
                                cloneNext(idx + 1);
                            });
                        };
                        cloneNext(0);
                    }
                }
            }

            Repeater {
                model: root.githubRepos

                Rectangle {
                    id: ghCard
                    Layout.fillWidth: true
                    height: 58
                    radius: 10
                    color: ghCardMouse.containsMouse ? themeManager.bgCardHover : (themeManager.isDark ? Qt.rgba(19/255, 27/255, 43/255, 0.7) : themeManager.bgCard)
                    border.color: ghCardMouse.containsMouse ? Qt.rgba(56/255, 189/255, 248/255, 0.4) : themeManager.borderPrimary
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    property var itemData: modelData

                    MouseArea {
                        id: ghCardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.NoButton
                    }

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12

                        AppIcon {
                            name: itemData.is_cloned ? "repo" : "github"
                            size: 18
                            color: itemData.is_cloned ? themeManager.accent : themeManager.textSecondary
                        }

                        Column {
                            spacing: 2
                            Row {
                                spacing: 8
                                Text {
                                    text: itemData.full_name || itemData.name
                                    color: themeManager.textPrimary
                                    font.pixelSize: 13
                                    font.weight: Font.DemiBold
                                }
                                Text {
                                    text: itemData.private ? "Private" : "Public"
                                    color: themeManager.textMuted
                                    font.pixelSize: 11
                                }
                            }
                            Text {
                                text: itemData.description || "No description provided"
                                color: themeManager.textMuted
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                Layout.maximumWidth: 420
                            }
                        }

                        Item { Layout.fillWidth: true }

                        StatusBadge {
                            status: itemData.is_cloned ? "Cloned" : "Remote Only"
                            small: true
                        }

                        ActionButton {
                            visible: !itemData.is_cloned
                            text: "Clone & Track"
                            iconName: "pull"
                            btnStyle: "primary"
                            small: true
                            onClicked: {
                                var target = "D:/DevSyncProjects/" + itemData.name;
                                toast.show("Cloning " + itemData.name + "...", "info");
                                backendBridge.sendRequest("git.clone", {"url": itemData.clone_url, "target_dir": target, "name": itemData.name}, function(success, data, err) {
                                    if (success) {
                                        toast.show("Cloned " + itemData.name + " into workspace!", "success");
                                        root.loadGitHubRepos();
                                        root.requestQuickAction("refresh_all", null);
                                    } else {
                                        toast.show("Clone failed: " + err, "error");
                                    }
                                });
                            }
                        }

                        ActionButton {
                            visible: !!itemData.is_cloned
                            text: "View Details"
                            iconName: "search"
                            btnStyle: "secondary"
                            small: true
                            onClicked: root.openProjectDetails(itemData.project_id)
                        }

                        ActionButton {
                            text: "Open"
                            iconName: "external"
                            btnStyle: "subtle"
                            small: true
                            onClicked: backendBridge.openUrl(itemData.html_url)
                        }
                    }
                }
            }
        }

        // Empty state if neither local nor GitHub repos
        Rectangle {
            visible: projectModel.count === 0 && root.githubRepos.length === 0
            Layout.fillWidth: true
            height: 200
            radius: 8
            color: themeManager.bgCard
            border.color: themeManager.borderPrimary
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: 12

                AppIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "repo"
                    size: 32
                    color: themeManager.accent
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No projects in workspace"
                    color: themeManager.textPrimary
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Add an existing local folder or connect your GitHub account to manage repositories."
                    color: themeManager.textSecondary
                    font.pixelSize: 13
                }

                ActionButton {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Add Project Folder"
                    iconName: "plus"
                    btnStyle: "primary"
                    onClicked: root.requestQuickAction("add_project", null)
                }
            }
        }
    }
}
