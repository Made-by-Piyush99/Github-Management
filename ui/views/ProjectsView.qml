import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

ScrollView {
    id: root

    property string filterQuery: ""
    property string statusFilter: "all" // all, git, modified, pinned
    property var githubRepos: []

    signal openProject(string projectId)
    signal refreshRequested()

    contentWidth: availableWidth
    clip: true

    function loadGitHubRepos() {
        backendBridge.sendRequest("github.repositories", {}, function(success, data) {
            if (success && data && data.repositories) {
                root.githubRepos = data.repositories;
            }
        });
    }

    Component.onCompleted: {
        loadGitHubRepos();
    }

    ColumnLayout {
        width: parent.width
        anchors.margins: 24
        spacing: 20

        // Header Action Bar
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Column {
                spacing: 2
                Text {
                    text: "Project Management"
                    color: themeManager.textPrimary
                    font.pixelSize: 18
                    font.weight: Font.Bold
                }
                Text {
                    text: "Manage registered projects, clone from GitHub, or initialize local repositories."
                    color: themeManager.textSecondary
                    font.pixelSize: 12
                }
            }

            Item { Layout.fillWidth: true }

            ActionButton {
                text: "Create New Repository"
                iconText: "➕"
                btnStyle: "primary"
                onClicked: appWindow.openCreateRepoDialog()
            }

            ActionButton {
                text: "Add Local Folder"
                iconText: "📂"
                btnStyle: "secondary"
                onClicked: {
                    var folder = backendBridge.selectFolder("Choose Project Directory", "");
                    if (folder) {
                        backendBridge.sendRequest("projects.add", {"path": folder}, function(success, data, error) {
                            if (success) {
                                toast.show("Project added successfully!", "success");
                                root.refreshRequested();
                            } else {
                                toast.show("Failed to add project: " + error, "error");
                            }
                        });
                    }
                }
            }

            ActionButton {
                text: "Clone from GitHub"
                iconText: "📥"
                btnStyle: "primary"
                onClicked: {
                    // Navigate to Repositories tab or GitHub tab to clone
                    appWindow.activeTab = 2; // Repositories view
                }
            }
        }

        // Filter Pills
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ActionButton {
                text: "All (" + projectModel.count + ")"
                btnStyle: root.statusFilter === "all" ? "primary" : "subtle"
                small: true
                onClicked: root.statusFilter = "all"
            }

            ActionButton {
                text: "Git Only"
                btnStyle: root.statusFilter === "git" ? "primary" : "subtle"
                small: true
                onClicked: root.statusFilter = "git"
            }

            ActionButton {
                text: "Modified"
                btnStyle: root.statusFilter === "modified" ? "primary" : "subtle"
                small: true
                onClicked: root.statusFilter = "modified"
            }

            ActionButton {
                text: "Pinned"
                btnStyle: root.statusFilter === "pinned" ? "primary" : "subtle"
                small: true
                onClicked: root.statusFilter = "pinned"
            }
        }

        // Project List
        ListView {
            visible: projectModel.count > 0
            Layout.fillWidth: true
            implicitHeight: contentHeight
            interactive: false
            spacing: 12
            model: projectModel

            delegate: Rectangle {
                id: projRow
                width: ListView.view.width
                implicitHeight: col.implicitHeight + 28
                radius: 8
                color: mouseA.containsMouse ? themeManager.bgCardHover : themeManager.bgCard
                border.color: themeManager.borderPrimary
                border.width: 1

                property var pData: projectModel.get(index)

                visible: {
                    if (root.statusFilter === "git" && !pData.is_git_repo) return false;
                    if (root.statusFilter === "modified" && (pData.uncommitted_count || 0) === 0) return false;
                    if (root.statusFilter === "pinned" && !pData.is_pinned) return false;
                    if (!root.filterQuery) return true;
                    var q = root.filterQuery.toLowerCase();
                    return (pData.name || "").toLowerCase().indexOf(q) !== -1 || (pData.local_path || "").toLowerCase().indexOf(q) !== -1;
                }

                MouseArea {
                    id: mouseA
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: root.openProject(pData.id)
                }

                ColumnLayout {
                    id: col
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 10

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: pData.is_pinned ? "📌" : "📁"
                            font.pixelSize: 16
                        }

                        Text {
                            text: pData.name || "Untitled"
                            color: themeManager.textPrimary
                            font.pixelSize: 15
                            font.weight: Font.Bold
                        }

                        StatusBadge {
                            status: pData.status || "Unknown"
                            small: true
                        }

                        Item { Layout.fillWidth: true }

                        ActionButton {
                            visible: !pData.is_git_repo
                            text: "Initialize Git"
                            iconText: "⚡"
                            btnStyle: "primary"
                            small: true
                            onClicked: {
                                confirmDialog.open(
                                    "Initialize Git Repository",
                                    "Initialize a new Git repository in:\n" + pData.local_path,
                                    function() {
                                        backendBridge.sendRequest("git.init", {"path": pData.local_path, "project_id": pData.id}, function(success, data, err) {
                                            if (success) {
                                                toast.show("Git repository initialized!", "success");
                                                root.refreshRequested();
                                            } else {
                                                toast.show("Failed to init git: " + err, "error");
                                            }
                                        });
                                    },
                                    "primary",
                                    "Initialize"
                                );
                            }
                        }

                        ActionButton {
                            text: pData.is_pinned ? "Unpin" : "Pin"
                            iconText: "📌"
                            btnStyle: "subtle"
                            small: true
                            onClicked: {
                                backendBridge.sendRequest("projects.set_pinned", {"id": pData.id, "is_pinned": !pData.is_pinned}, function(s) {
                                    if (s) root.refreshRequested();
                                });
                            }
                        }

                        ActionButton {
                            text: "Remove"
                            iconText: "🗑️"
                            btnStyle: "subtle"
                            small: true
                            onClicked: {
                                confirmDialog.open(
                                    "Remove Project",
                                    "Are you sure you want to remove '" + pData.name + "' from DevSync Studio?\n\nNote: Your local files and Git history will NOT be deleted.",
                                    function() {
                                        backendBridge.sendRequest("projects.remove", {"id": pData.id}, function(success, data, err) {
                                            if (success) {
                                                toast.show("Project removed from application.", "info");
                                                root.refreshRequested();
                                            } else {
                                                toast.show("Failed to remove: " + err, "error");
                                            }
                                        });
                                    },
                                    "danger",
                                    "Remove"
                                );
                            }
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12

                        Text {
                            text: "Path: " + pData.local_path
                            color: themeManager.textMuted
                            font.pixelSize: 11
                            elide: Text.ElideMiddle
                            Layout.maximumWidth: 380
                        }

                        Text {
                            visible: !!pData.git_remote
                            text: "Remote: " + pData.git_remote
                            color: themeManager.accent
                            font.pixelSize: 11
                            elide: Text.ElideMiddle
                            Layout.maximumWidth: 320
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: pData.current_branch ? ("Branch: " + pData.current_branch) : "No branch"
                            color: themeManager.textSecondary
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }

        // Quick Clone Prompt if 0 local projects but GitHub has repos
        Rectangle {
            visible: projectModel.count === 0 && root.githubRepos.length > 0
            Layout.fillWidth: true
            implicitHeight: ghPromptCol.implicitHeight + 36
            radius: 8
            color: themeManager.bgCard
            border.color: themeManager.borderPrimary
            border.width: 1

            ColumnLayout {
                id: ghPromptCol
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Text { text: "🐙"; font.pixelSize: 20 }
                    Text {
                        text: "Repositories Available on GitHub (" + root.githubRepos.length + ")"
                        color: themeManager.textPrimary
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }
                    Item { Layout.fillWidth: true }
                }

                Text {
                    text: "You are connected to GitHub! Click 'Clone to Local' on any repository below to add it directly to your workspace."
                    color: themeManager.textSecondary
                    font.pixelSize: 12
                }

                Repeater {
                    model: root.githubRepos

                    Rectangle {
                        Layout.fillWidth: true
                        height: 48
                        radius: 6
                        color: themeManager.bgPrimary
                        border.color: themeManager.borderPrimary
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 10

                            Text { text: "📦"; font.pixelSize: 13 }
                            Text {
                                text: modelData.name
                                color: themeManager.textPrimary
                                font.pixelSize: 13
                                font.weight: Font.Medium
                            }
                            Text {
                                visible: !!modelData.description
                                text: "• " + modelData.description
                                color: themeManager.textMuted
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                            Item { visible: !modelData.description; Layout.fillWidth: true }

                            ActionButton {
                                text: "Clone to Local"
                                iconText: "📥"
                                btnStyle: "primary"
                                small: true
                                onClicked: {
                                    var target = "D:/DevSyncProjects/" + modelData.name;
                                    toast.show("Cloning " + modelData.name + "...", "info");
                                    backendBridge.sendRequest("git.clone", {"url": modelData.clone_url, "target_dir": target, "name": modelData.name}, function(success, data, err) {
                                        if (success) {
                                            toast.show("Cloned " + modelData.name + " into workspace!", "success");
                                            root.refreshRequested();
                                        } else {
                                            toast.show("Clone failed: " + err, "error");
                                        }
                                    });
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
