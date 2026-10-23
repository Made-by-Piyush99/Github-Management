import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

ScrollView {
    id: root

    property string selectedProjectId: ""
    property var branchesData: ({ local: [], remote: [] })
    property bool loading: false

    signal refreshRequested()

    contentWidth: availableWidth
    clip: true

    function loadBranches() {
        if (!selectedProjectId) {
            if (projectModel.count > 0) {
                selectedProjectId = projectModel.get(0).id;
            } else {
                return;
            }
        }

        var idx = projectModel.indexOf(selectedProjectId);
        if (idx === -1) return;
        var proj = projectModel.get(idx);
        if (!proj.is_git_repo) return;

        loading = true;
        backendBridge.sendRequest("git.branches", {"path": proj.local_path}, function(success, data, err) {
            loading = false;
            if (success) {
                branchesData = data;
            } else {
                toast.show("Failed to load branches: " + err, "error");
            }
        });
    }

    Component.onCompleted: {
        loadBranches();
    }

    ColumnLayout {
        width: parent.width
        anchors.margins: 24
        spacing: 20

        // Top bar: Project selector & Create Branch button
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Column {
                spacing: 2
                Text {
                    text: "Branch Management"
                    color: themeManager.textPrimary
                    font.pixelSize: 18
                    font.weight: Font.Bold
                }
                Text {
                    text: "Switch branches, create feature branches, and manage remote tracking."
                    color: themeManager.textSecondary
                    font.pixelSize: 12
                }
            }

            Item { Layout.fillWidth: true }

            // Project Selector Combo
            StyledComboBox {
                id: projCombo
                Layout.preferredWidth: 220
                model: projectModel
                textRole: "name"
                currentIndex: projectModel.indexOf(root.selectedProjectId)
                onActivated: function(index) {
                    var p = projectModel.get(index);
                    root.selectedProjectId = p.id;
                    root.loadBranches();
                }
            }

            ActionButton {
                text: "New Branch"
                iconName: "branch"
                btnStyle: "primary"
                onClicked: {
                    var idx = projectModel.indexOf(root.selectedProjectId);
                    if (idx === -1) return;
                    var proj = projectModel.get(idx);

                    textInputDialog.open(
                        "Create New Branch",
                        "Enter the name for the new branch:",
                        "feature/new-feature",
                        "",
                        function(branchName) {
                            backendBridge.sendRequest(
                                "git.create_branch",
                                {"path": proj.local_path, "project_id": proj.id, "name": branchName, "checkout": true},
                                function(success, data, err) {
                                    if (success) {
                                        toast.show("Branch '" + branchName + "' created and checked out!", "success");
                                        root.loadBranches();
                                        root.refreshRequested();
                                    } else {
                                        toast.show("Failed: " + err, "error");
                                    }
                                }
                            );
                        }
                    );
                }
            }
        }

        // Local Branches Section
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "LOCAL BRANCHES"
                color: themeManager.textMuted
                font.pixelSize: 11
                font.weight: Font.Bold
            }

            Repeater {
                model: root.branchesData.local || []

                Rectangle {
                    id: branchItem
                    Layout.fillWidth: true
                    height: 52
                    radius: 8
                    color: modelData.is_current
                           ? (themeManager.isDark ? Qt.rgba(56/255, 189/255, 248/255, 0.12) : themeManager.accentMuted)
                           : (branchMouse.containsMouse ? themeManager.bgCardHover : (themeManager.isDark ? Qt.rgba(19/255, 27/255, 43/255, 0.7) : themeManager.bgCard))
                    border.color: modelData.is_current ? themeManager.accent : (branchMouse.containsMouse ? themeManager.borderSecondary : themeManager.borderPrimary)
                    border.width: 1

                    Behavior on color { ColorAnimation { duration: 120 } }
                    Behavior on border.color { ColorAnimation { duration: 120 } }

                    MouseArea {
                        id: branchMouse
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
                            name: modelData.is_current ? "check" : "branch"
                            size: 14
                            color: modelData.is_current ? themeManager.accent : themeManager.textSecondary
                        }

                        Column {
                            spacing: 2
                            Row {
                                spacing: 8
                                Text {
                                    text: modelData.name
                                    color: modelData.is_current ? themeManager.accent : themeManager.textPrimary
                                    font.pixelSize: 14
                                    font.weight: modelData.is_current ? Font.Bold : Font.Medium
                                }
                                Rectangle {
                                    visible: modelData.is_current
                                    height: 18
                                    width: curLabel.implicitWidth + 8
                                    radius: 4
                                    color: themeManager.accent
                                    Text {
                                        id: curLabel
                                        anchors.centerIn: parent
                                        text: "CURRENT"
                                        color: "#FFFFFF"
                                        font.pixelSize: 9
                                        font.weight: Font.Bold
                                    }
                                }
                            }

                            Text {
                                text: modelData.subject ? (modelData.commit_hash + " - " + modelData.subject + " (" + modelData.date + ")") : "No commit details"
                                color: themeManager.textMuted
                                font.pixelSize: 11
                            }
                        }

                        Item { Layout.fillWidth: true }

                        // Tracking pill
                        Text {
                            visible: !!modelData.upstream
                            text: "Tracks: " + modelData.upstream
                            color: themeManager.textSecondary
                            font.pixelSize: 11
                        }

                        // Switch Branch Button
                        ActionButton {
                            visible: !modelData.is_current
                            text: "Switch"
                            iconName: "branch"
                            btnStyle: "secondary"
                            small: true
                            onClicked: {
                                var idx = projectModel.indexOf(root.selectedProjectId);
                                if (idx === -1) return;
                                var proj = projectModel.get(idx);

                                backendBridge.sendRequest(
                                    "git.switch_branch",
                                    {"path": proj.local_path, "project_id": proj.id, "name": modelData.name},
                                    function(success, data, err) {
                                        if (success) {
                                            toast.show("Switched to branch '" + modelData.name + "'.", "success");
                                            root.loadBranches();
                                            root.refreshRequested();
                                        } else {
                                            toast.show("Cannot switch: " + err, "error");
                                        }
                                    }
                                );
                            }
                        }

                        // Delete Branch Button
                        ActionButton {
                            visible: !modelData.is_current
                            text: "Delete"
                            iconName: "trash"
                            btnStyle: "subtle"
                            small: true
                            onClicked: {
                                var idx = projectModel.indexOf(root.selectedProjectId);
                                if (idx === -1) return;
                                var proj = projectModel.get(idx);

                                confirmDialog.open(
                                    "Delete Branch",
                                    "Are you sure you want to delete branch '" + modelData.name + "'?",
                                    function() {
                                        backendBridge.sendRequest(
                                            "git.delete_branch",
                                            {"path": proj.local_path, "project_id": proj.id, "name": modelData.name, "force": false},
                                            function(success, data, err) {
                                                if (success) {
                                                    toast.show("Branch '" + modelData.name + "' deleted.", "info");
                                                    root.loadBranches();
                                                    root.refreshRequested();
                                                } else {
                                                    toast.show("Failed to delete branch: " + err, "error");
                                                }
                                            }
                                        );
                                    },
                                    "danger",
                                    "Delete Branch"
                                );
                            }
                        }
                    }
                }
            }
        }

        // Remote Branches Section
        ColumnLayout {
            visible: (root.branchesData.remote || []).length > 0
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: "REMOTE BRANCHES"
                color: themeManager.textMuted
                font.pixelSize: 11
                font.weight: Font.Bold
            }

            Repeater {
                model: root.branchesData.remote || []

                Rectangle {
                    Layout.fillWidth: true
                    height: 44
                    radius: 6
                    color: themeManager.bgCard
                    border.color: themeManager.borderPrimary
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 10

                        AppIcon { name: "github"; size: 13; color: themeManager.textMuted }

                        Text {
                            text: modelData.name
                            color: themeManager.textPrimary
                            font.pixelSize: 13
                            font.weight: Font.Medium
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: modelData.commit_hash || ""
                            color: themeManager.textMuted
                            font.family: "Consolas, monospace"
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }
    }
}
