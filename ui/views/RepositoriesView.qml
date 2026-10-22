import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

ScrollView {
    id: root

    property string filterText: ""
    signal openProject(string projectId)
    signal refreshRequested()

    contentWidth: availableWidth
    clip: true

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
                    text: "Inspect remote tracking, perform fetch, pull, and push operations safely."
                    color: themeManager.textSecondary
                    font.pixelSize: 12
                }
            }

            Item { Layout.fillWidth: true }
        }

        // Repositories Table / Card List
        ListView {
            Layout.fillWidth: true
            implicitHeight: contentHeight
            interactive: false
            spacing: 12
            model: projectModel

            delegate: Rectangle {
                id: repoCard
                width: ListView.view.width
                implicitHeight: repoCol.implicitHeight + 28
                radius: 8
                color: themeManager.bgCard
                border.color: themeManager.borderPrimary
                border.width: 1

                property var pData: projectModel.get(index)

                visible: pData.is_git_repo

                ColumnLayout {
                    id: repoCol
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 12

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Text {
                            text: "📦"
                            font.pixelSize: 16
                        }

                        Text {
                            text: pData.name
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
                            visible: !!pData.git_remote
                            text: "Open GitHub"
                            iconText: "↗️"
                            btnStyle: "subtle"
                            small: true
                            onClicked: {
                                var url = pData.git_remote;
                                if (url.startsWith("git@github.com:")) {
                                    url = "https://github.com/" + url.substring(15).replace(".git", "");
                                }
                                backendBridge.openUrl(url);
                            }
                        }

                        ActionButton {
                            text: "Fetch"
                            iconText: "🔄"
                            btnStyle: "secondary"
                            small: true
                            onClicked: {
                                toast.show("Fetching remote changes...", "info");
                                backendBridge.sendRequest("git.fetch", {"path": pData.local_path, "project_id": pData.id}, function(success, data, err) {
                                    if (success) {
                                        toast.show("Fetch completed.", "success");
                                        root.refreshRequested();
                                    } else {
                                        toast.show("Fetch failed: " + err, "error");
                                    }
                                });
                            }
                        }

                        ActionButton {
                            text: "Pull"
                            iconText: "⬇️"
                            btnStyle: "secondary"
                            small: true
                            onClicked: {
                                toast.show("Pulling from remote...", "info");
                                backendBridge.sendRequest("git.pull", {"path": pData.local_path, "project_id": pData.id}, function(success, data, err) {
                                    if (success) {
                                        if (data && data.is_conflict) {
                                            toast.show("Merge conflict encountered! Please check files.", "warning");
                                        } else {
                                            toast.show("Pull completed successfully.", "success");
                                        }
                                        root.refreshRequested();
                                    } else {
                                        toast.show("Pull failed: " + err, "error");
                                    }
                                });
                            }
                        }

                        ActionButton {
                            text: "Push"
                            iconText: "⬆️"
                            btnStyle: "primary"
                            small: true
                            onClicked: {
                                toast.show("Pushing commits to remote...", "info");
                                backendBridge.sendRequest("git.push", {"path": pData.local_path, "project_id": pData.id}, function(success, data, err) {
                                    if (success) {
                                        toast.show("Push completed successfully.", "success");
                                        root.refreshRequested();
                                    } else {
                                        toast.show("Push failed: " + err, "error");
                                    }
                                });
                            }
                        }
                    }

                    // Metadata details
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        rowSpacing: 6
                        columnSpacing: 16

                        Text {
                            text: "Local Branch: " + (pData.current_branch || "None")
                            color: themeManager.textSecondary
                            font.pixelSize: 12
                        }

                        Text {
                            text: "Remote URL: " + (pData.git_remote || "No remote configured")
                            color: pData.git_remote ? themeManager.accent : themeManager.textMuted
                            font.pixelSize: 12
                            elide: Text.ElideMiddle
                        }

                        Text {
                            text: "Sync: " + (pData.ahead || 0) + " ahead, " + (pData.behind || 0) + " behind"
                            color: themeManager.textSecondary
                            font.pixelSize: 12
                        }
                    }
                }
            }
        }
    }
}
