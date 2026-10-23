import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

ScrollView {
    id: root

    property string filterText: ""
    property string activeFilter: "all" // all, cloned, remote
    property var repoList: []
    property bool loading: false

    signal openProject(string projectId)
    signal refreshRequested()

    contentWidth: availableWidth
    clip: true

    function loadRepositories() {
        loading = true;
        backendBridge.sendRequest("github.repositories", {}, function(success, data, err) {
            loading = false;
            if (success && data && data.repositories) {
                repoList = data.repositories;
            } else {
                // If GitHub is not connected or error, fall back to local projectModel
                var list = [];
                for (var i = 0; i < projectModel.count; ++i) {
                    var p = projectModel.get(i);
                    if (p.is_git_repo) {
                        list.push({
                            "name": p.name,
                            "full_name": p.name,
                            "html_url": p.git_remote || "",
                            "clone_url": p.git_remote || "",
                            "private": false,
                            "description": "",
                            "stargazers_count": 0,
                            "is_cloned": true,
                            "project_id": p.id,
                            "local_path": p.local_path,
                            "status": p.status || "Unknown",
                            "current_branch": p.current_branch || "main",
                            "ahead": p.ahead || 0,
                            "behind": p.behind || 0,
                        });
                    }
                }
                repoList = list;
            }
        });
    }

    Component.onCompleted: {
        loadRepositories();
    }

    ColumnLayout {
        width: parent.width
        anchors.margins: 24
        spacing: 20

        // Header
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Column {
                spacing: 2
                Text {
                    text: "Repositories & Remotes"
                    color: themeManager.textPrimary
                    font.pixelSize: 18
                    font.weight: Font.Bold
                }
                Text {
                    text: "Manage local repositories and remote GitHub repositories with 1-click clone and sync."
                    color: themeManager.textSecondary
                    font.pixelSize: 12
                }
            }

            Item { Layout.fillWidth: true }

            ActionButton {
                text: "Create New Repository"
                iconName: "plus"
                btnStyle: "primary"
                onClicked: appWindow.openCreateRepoDialog()
            }

            ActionButton {
                text: "Refresh"
                iconName: "refresh"
                btnStyle: "subtle"
                busy: root.loading
                onClicked: {
                    root.loadRepositories();
                    root.refreshRequested();
                }
            }
        }

        // Filter Pills
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ActionButton {
                text: "All Repositories (" + root.repoList.length + ")"
                btnStyle: root.activeFilter === "all" ? "primary" : "subtle"
                small: true
                onClicked: root.activeFilter = "all"
            }

            ActionButton {
                text: "Local / Cloned"
                btnStyle: root.activeFilter === "cloned" ? "primary" : "subtle"
                small: true
                onClicked: root.activeFilter = "cloned"
            }

            ActionButton {
                text: "Remote on GitHub"
                btnStyle: root.activeFilter === "remote" ? "primary" : "subtle"
                small: true
                onClicked: root.activeFilter = "remote"
            }
        }

        // Empty state when no repos found
        Rectangle {
            visible: root.repoList.length === 0 && !root.loading
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
                    text: "No repositories detected"
                    color: themeManager.textPrimary
                    font.pixelSize: 15
                    font.weight: Font.Bold
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Connect your GitHub account in the GitHub tab or add a local folder to view repositories."
                    color: themeManager.textSecondary
                    font.pixelSize: 12
                }
            }
        }

        // Repositories List
        Repeater {
            model: root.repoList

            Rectangle {
                id: repoCard
                Layout.fillWidth: true
                implicitHeight: repoCol.implicitHeight + 28
                radius: 10
                color: repoMouse.containsMouse ? themeManager.bgCardHover : (themeManager.isDark ? Qt.rgba(19/255, 27/255, 43/255, 0.7) : themeManager.bgCard)
                border.color: repoMouse.containsMouse ? Qt.rgba(56/255, 189/255, 248/255, 0.4) : themeManager.borderPrimary
                border.width: 1

                Behavior on color { ColorAnimation { duration: 120 } }
                Behavior on border.color { ColorAnimation { duration: 120 } }

                MouseArea {
                    id: repoMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    acceptedButtons: Qt.NoButton
                }

                // Top edge subtle glow
                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 1
                    height: 1
                    radius: 10
                    color: repoMouse.containsMouse ? Qt.rgba(56/255, 189/255, 248/255, 0.3) : Qt.rgba(255, 255, 255, 0.05)
                    visible: themeManager.isDark
                }

                property var rData: modelData

                visible: {
                    if (root.activeFilter === "cloned" && !rData.is_cloned) return false;
                    if (root.activeFilter === "remote" && rData.is_cloned) return false;
                    if (!root.filterText) return true;
                    var q = root.filterText.toLowerCase();
                    return (rData.name || "").toLowerCase().indexOf(q) !== -1 || (rData.full_name || "").toLowerCase().indexOf(q) !== -1;
                }

                ColumnLayout {
                    id: repoCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        AppIcon {
                            name: rData.is_cloned ? "repo" : "github"
                            size: 16
                            color: rData.is_cloned ? themeManager.accent : themeManager.textSecondary
                        }

                        Column {
                            spacing: 2
                            Text {
                                text: rData.full_name || rData.name
                                color: themeManager.textPrimary
                                font.pixelSize: 15
                                font.weight: Font.Bold
                            }
                            Text {
                                visible: !!rData.description
                                text: rData.description
                                color: themeManager.textMuted
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                Layout.maximumWidth: 400
                            }
                        }

                        StatusBadge {
                            status: rData.status || (rData.is_cloned ? "Synced" : "Remote on GitHub")
                            small: true
                        }

                        Item { Layout.fillWidth: true }

                        // If not cloned: Show 1-Click Clone Button
                        ActionButton {
                            visible: !rData.is_cloned
                            text: "Clone to Local"
                            iconName: "pull"
                            btnStyle: "primary"
                            small: true
                            onClicked: {
                                var target = "D:/DevSyncProjects/" + rData.name;
                                toast.show("Cloning " + rData.name + "...", "info");
                                backendBridge.sendRequest("git.clone", {"url": rData.clone_url, "target_dir": target, "name": rData.name}, function(success, data, err) {
                                    if (success) {
                                        toast.show("Cloned " + rData.name + " to " + target, "success");
                                        root.loadRepositories();
                                        root.refreshRequested();
                                    } else {
                                        toast.show("Clone failed: " + err, "error");
                                    }
                                });
                            }
                        }

                        // If cloned: Show Fetch / Pull / Push actions
                        ActionButton {
                            visible: !!rData.is_cloned
                            text: "Fetch"
                            iconName: "refresh"
                            btnStyle: "secondary"
                            small: true
                            onClicked: {
                                toast.show("Fetching remote changes...", "info");
                                backendBridge.sendRequest("git.fetch", {"path": rData.local_path, "project_id": rData.project_id}, function(success, data, err) {
                                    if (success) {
                                        toast.show("Fetch completed.", "success");
                                        root.loadRepositories();
                                        root.refreshRequested();
                                    } else {
                                        toast.show("Fetch failed: " + err, "error");
                                    }
                                });
                            }
                        }

                        ActionButton {
                            visible: !!rData.is_cloned
                            text: "Pull"
                            iconName: "pull"
                            btnStyle: "secondary"
                            small: true
                            onClicked: {
                                toast.show("Pulling from remote...", "info");
                                backendBridge.sendRequest("git.pull", {"path": rData.local_path, "project_id": rData.project_id}, function(success, data, err) {
                                    if (success) {
                                        toast.show("Pull completed successfully.", "success");
                                        root.loadRepositories();
                                        root.refreshRequested();
                                    } else {
                                        toast.show("Pull failed: " + err, "error");
                                    }
                                });
                            }
                        }

                        ActionButton {
                            visible: !!rData.is_cloned
                            text: "Push"
                            iconName: "push"
                            btnStyle: "primary"
                            small: true
                            onClicked: {
                                toast.show("Pushing commits to remote...", "info");
                                backendBridge.sendRequest("git.push", {"path": rData.local_path, "project_id": rData.project_id}, function(success, data, err) {
                                    if (success) {
                                        toast.show("Push completed successfully.", "success");
                                        root.loadRepositories();
                                        root.refreshRequested();
                                    } else {
                                        toast.show("Push failed: " + err, "error");
                                    }
                                });
                            }
                        }

                        ActionButton {
                            visible: !!rData.html_url
                            text: "Open GitHub"
                            iconName: "external"
                            btnStyle: "subtle"
                            small: true
                            onClicked: backendBridge.openUrl(rData.html_url)
                        }
                    }

                    // Metadata details
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 16

                        Row {
                            spacing: 6
                            AppIcon {
                                name: rData.is_cloned ? "folder" : "github"
                                size: 12
                                color: themeManager.textMuted
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: rData.is_cloned ? ("Local: " + rData.local_path) : "Remote Only (Not cloned to local disk)"
                                color: themeManager.textMuted
                                font.pixelSize: 11
                                elide: Text.ElideMiddle
                                width: Math.min(320, implicitWidth)
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Row {
                            spacing: 5
                            AppIcon {
                                name: "branch"
                                size: 11
                                color: themeManager.accent
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            Text {
                                text: rData.current_branch || "main"
                                color: themeManager.textSecondary
                                font.pixelSize: 11
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            visible: !!rData.is_cloned
                            text: (rData.ahead || 0) + " ahead, " + (rData.behind || 0) + " behind"
                            color: themeManager.textSecondary
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}
