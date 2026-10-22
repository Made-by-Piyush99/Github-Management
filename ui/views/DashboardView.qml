import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

ScrollView {
    id: root

    property string filterText: ""
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

    function updateMetrics() {
        var gitCount = 0;
        var ghCount = 0;
        var uncomm = 0;
        var pushes = 0;
        var pulls = 0;
        var errors = 0;

        for (var i = 0; i < projectModel.count; ++i) {
            var p = projectModel.get(i);
            if (p.is_git_repo) gitCount++;
            if (p.has_github_remote) ghCount++;
            if ((p.uncommitted_count || 0) > 0) uncomm++;
            if ((p.ahead || 0) > 0) pushes++;
            if ((p.behind || 0) > 0) pulls++;
            var st = (p.status || "").toLowerCase();
            if (st.indexOf("conflict") !== -1 || st.indexOf("error") !== -1) errors++;
        }

        gitReposCount = gitCount;
        githubReposCount = ghCount;
        uncommittedCount = uncomm;
        pendingPushesCount = pushes;
        pendingPullsCount = pulls;
        syncErrorsCount = errors;
    }

    Connections {
        target: projectModel
        function onCountChanged() { root.updateMetrics(); }
    }

    Component.onCompleted: {
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

            Text {
                text: "WORKSPACE SUMMARY"
                color: themeManager.textMuted
                font.pixelSize: 11
                font.weight: Font.Bold
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
                    iconText: "📁"
                    highlightColor: themeManager.accent
                }

                StatCard {
                    Layout.fillWidth: true
                    title: "Git Repositories"
                    value: "" + root.gitReposCount
                    subtext: "Active local repositories"
                    iconText: "🌿"
                    highlightColor: themeManager.success
                }

                StatCard {
                    Layout.fillWidth: true
                    title: "GitHub Connected"
                    value: "" + root.githubReposCount
                    subtext: "Linked to remote"
                    iconText: "🐙"
                    highlightColor: themeManager.info
                }

                StatCard {
                    Layout.fillWidth: true
                    title: "Uncommitted Changes"
                    value: "" + root.uncommittedCount
                    subtext: "Require commit / review"
                    iconText: "📝"
                    highlightColor: themeManager.warning
                    isWarning: root.uncommittedCount > 0
                }

                StatCard {
                    Layout.fillWidth: true
                    title: "Pending Pushes"
                    value: "" + root.pendingPushesCount
                    subtext: "Ahead of remote"
                    iconText: "⬆️"
                    highlightColor: themeManager.accent
                }

                StatCard {
                    Layout.fillWidth: true
                    title: "Pending Pulls"
                    value: "" + root.pendingPullsCount
                    subtext: "Behind remote"
                    iconText: "⬇️"
                    highlightColor: themeManager.warning
                }

                StatCard {
                    Layout.fillWidth: true
                    title: "Sync Errors & Conflicts"
                    value: "" + root.syncErrorsCount
                    subtext: root.syncErrorsCount === 0 ? "All remotes healthy" : "Requires resolution"
                    iconText: "⚠️"
                    highlightColor: themeManager.danger
                    isWarning: root.syncErrorsCount > 0
                }

                StatCard {
                    Layout.fillWidth: true
                    title: "Synchronization Status"
                    value: root.syncErrorsCount > 0 ? "Issues" : "Healthy"
                    subtext: "Verified local & remote"
                    iconText: "🔄"
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

        // Empty state if no projects
        Rectangle {
            visible: projectModel.count === 0
            Layout.fillWidth: true
            height: 220
            radius: 8
            color: themeManager.bgCard
            border.color: themeManager.borderPrimary
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: 12

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "🚀"
                    font.pixelSize: 32
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No projects added yet"
                    color: themeManager.textPrimary
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Add an existing project folder or initialize Git to start managing your code."
                    color: themeManager.textSecondary
                    font.pixelSize: 13
                }

                ActionButton {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Add Project Folder"
                    iconText: "➕"
                    btnStyle: "primary"
                    onClicked: root.requestQuickAction("add_project", null)
                }
            }
        }

        // Projects List
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

                // Search filtering
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
    }
}
