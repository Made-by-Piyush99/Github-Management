import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Item {
    id: root

    property string selectedProjectId: ""
    property string activeFilePath: ""
    property var activeDiffData: null
    property bool activeFileIsStaged: false
    property bool loading: false

    signal refreshRequested()

    function loadStatus() {
        if (!selectedProjectId && projectModel.count > 0) {
            selectedProjectId = projectModel.get(0).id;
        }
        var idx = projectModel.indexOf(selectedProjectId);
        if (idx === -1) return;
        var proj = projectModel.get(idx);
        if (!proj.is_git_repo) return;

        backendBridge.sendRequest("git.status", {"path": proj.local_path}, function(success, data, err) {
            if (success) {
                fileStatusModel.setFiles(data.files || []);
                if (data.files && data.files.length > 0) {
                    if (!root.activeFilePath) {
                        root.loadFileDiff(data.files[0].path, data.files[0].is_staged);
                    }
                } else {
                    root.activeFilePath = "";
                    root.activeDiffData = null;
                }
            }
        });
    }

    function loadFileDiff(filePath, isStaged) {
        root.activeFilePath = filePath;
        root.activeFileIsStaged = !!isStaged;

        var idx = projectModel.indexOf(selectedProjectId);
        if (idx === -1) return;
        var proj = projectModel.get(idx);

        backendBridge.sendRequest("git.diff", {"path": proj.local_path, "file_path": filePath, "staged": !!isStaged}, function(success, data, err) {
            if (success) {
                root.activeDiffData = data;
            }
        });
    }

    Component.onCompleted: {
        loadStatus();
    }

    RowLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 16

        // Left Panel: Changed Files List & Commit Form
        Rectangle {
            Layout.preferredWidth: 360
            Layout.fillHeight: true
            radius: 10
            color: themeManager.isDark ? Qt.rgba(19/255, 27/255, 43/255, 0.75) : themeManager.bgCard
            border.color: themeManager.borderPrimary
            border.width: 1

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 12

                // Project selector
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    StyledComboBox {
                        Layout.fillWidth: true
                        model: projectModel
                        textRole: "name"
                        currentIndex: projectModel.indexOf(root.selectedProjectId)
                        onActivated: function(index) {
                            var p = projectModel.get(index);
                            root.selectedProjectId = p.id;
                            root.loadStatus();
                        }
                    }

                    ActionButton {
                        text: ""
                        iconName: "refresh"
                        btnStyle: "subtle"
                        small: true
                        onClicked: root.loadStatus()
                    }
                }

                // Stage / Unstage All Row
                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "CHANGES (" + fileStatusModel.count + ")"
                        color: themeManager.textMuted
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }

                    Item { Layout.fillWidth: true }

                    ActionButton {
                        text: "Stage All"
                        btnStyle: "subtle"
                        small: true
                        onClicked: {
                            var idx = projectModel.indexOf(root.selectedProjectId);
                            if (idx === -1) return;
                            backendBridge.sendRequest("git.stage_all", {"path": projectModel.get(idx).local_path}, function(s) {
                                if (s) root.loadStatus();
                            });
                        }
                    }

                    ActionButton {
                        text: "Unstage All"
                        btnStyle: "subtle"
                        small: true
                        onClicked: {
                            var idx = projectModel.indexOf(root.selectedProjectId);
                            if (idx === -1) return;
                            backendBridge.sendRequest("git.unstage_all", {"path": projectModel.get(idx).local_path}, function(s) {
                                if (s) root.loadStatus();
                            });
                        }
                    }
                }

                // File list
                ScrollView {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    clip: true

                    ListView {
                        width: parent.width
                        model: fileStatusModel
                        spacing: 2

                        delegate: Rectangle {
                            width: parent.width
                            height: 38
                            radius: 4
                            color: root.activeFilePath === model.path ? themeManager.accentMuted : (fileMouse.containsMouse ? themeManager.bgCardHover : "transparent")

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 8
                                anchors.rightMargin: 8
                                spacing: 8

                                // Stage checkbox
                                CheckBox {
                                    checked: model.is_staged
                                    onClicked: {
                                        var idx = projectModel.indexOf(root.selectedProjectId);
                                        if (idx === -1) return;
                                        var p = projectModel.get(idx);
                                        var cmd = model.is_staged ? "git.unstage" : "git.stage";
                                        backendBridge.sendRequest(cmd, {"path": p.local_path, "file_path": model.path}, function(s) {
                                            if (s) root.loadStatus();
                                        });
                                    }
                                }

                                Rectangle {
                                    width: 18
                                    height: 18
                                    radius: 3
                                    color: model.is_conflict ? Qt.rgba(239/255, 68/255, 68/255, 0.15)
                                         : (model.is_untracked ? Qt.rgba(245/255, 158/255, 11/255, 0.15)
                                         : (model.is_staged ? Qt.rgba(16/255, 185/255, 129/255, 0.15)
                                         : Qt.rgba(56/255, 189/255, 248/255, 0.15)))

                                    Text {
                                        anchors.centerIn: parent
                                        text: model.is_conflict ? "C" : (model.is_untracked ? "U" : (model.is_staged ? "A" : "M"))
                                        color: model.is_conflict ? themeManager.danger
                                             : (model.is_untracked ? themeManager.warning
                                             : (model.is_staged ? themeManager.success
                                             : themeManager.accent))
                                        font.pixelSize: 10
                                        font.weight: Font.Bold
                                    }
                                }

                                Text {
                                    text: model.path
                                    color: themeManager.textPrimary
                                    font.pixelSize: 12
                                    elide: Text.ElideMiddle
                                    Layout.fillWidth: true
                                }

                                // Discard change button
                                ActionButton {
                                    text: "✕"
                                    btnStyle: "subtle"
                                    small: true
                                    onClicked: {
                                        var idx = projectModel.indexOf(root.selectedProjectId);
                                        if (idx === -1) return;
                                        var p = projectModel.get(idx);
                                        var fPath = model.path;

                                        confirmDialog.open(
                                            "Discard Changes",
                                            "Are you sure you want to discard changes in '" + fPath + "'? This operation cannot be undone.",
                                            function() {
                                                backendBridge.sendRequest("git.discard", {"path": p.local_path, "file_path": fPath}, function(success, data, err) {
                                                    if (success) {
                                                        toast.show("Changes discarded.", "info");
                                                        root.loadStatus();
                                                    } else {
                                                        toast.show("Failed: " + err, "error");
                                                    }
                                                });
                                            },
                                            "danger",
                                            "Discard"
                                        );
                                    }
                                }
                            }

                            MouseArea {
                                id: fileMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                acceptedButtons: Qt.LeftButton
                                propagateComposedEvents: true
                                onClicked: function(mouse) {
                                    root.loadFileDiff(model.path, model.is_staged);
                                    mouse.accepted = false;
                                }
                            }
                        }
                    }
                }

                // Divider
                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: themeManager.borderPrimary
                }

                // Commit Section
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text {
                        text: "COMMIT MESSAGE"
                        color: themeManager.textMuted
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 70
                        radius: 8
                        color: themeManager.isDark ? Qt.rgba(255, 255, 255, 0.04) : themeManager.bgInput
                        border.color: commitInput.activeFocus ? themeManager.accent : (themeManager.isDark ? Qt.rgba(255, 255, 255, 0.1) : themeManager.borderPrimary)
                        border.width: 1

                        TextArea {
                            id: commitInput
                            anchors.fill: parent
                            anchors.margins: 8
                            color: themeManager.textPrimary
                            font.pixelSize: 12
                            placeholderText: "feat: describe your changes..."
                            background: null
                            wrapMode: TextArea.Wrap
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        ActionButton {
                            Layout.fillWidth: true
                            text: "Commit"
                            iconName: "commit"
                            btnStyle: "primary"
                            enabled: fileStatusModel.stagedCount > 0 && commitInput.text.trim() !== ""
                            onClicked: {
                                var idx = projectModel.indexOf(root.selectedProjectId);
                                if (idx === -1) return;
                                var p = projectModel.get(idx);
                                var msg = commitInput.text.trim();

                                backendBridge.sendRequest("git.commit", {"path": p.local_path, "project_id": p.id, "message": msg}, function(success, data, err) {
                                    if (success) {
                                        toast.show("Committed: " + msg, "success");
                                        commitInput.text = "";
                                        root.loadStatus();
                                        root.refreshRequested();
                                    } else {
                                        toast.show("Commit failed: " + err, "error");
                                    }
                                });
                            }
                        }

                        ActionButton {
                            text: "Commit & Push"
                            iconName: "push"
                            btnStyle: "secondary"
                            enabled: fileStatusModel.stagedCount > 0 && commitInput.text.trim() !== ""
                            onClicked: {
                                var idx = projectModel.indexOf(root.selectedProjectId);
                                if (idx === -1) return;
                                var p = projectModel.get(idx);
                                var msg = commitInput.text.trim();

                                backendBridge.sendRequest("git.commit", {"path": p.local_path, "project_id": p.id, "message": msg}, function(success, data, err) {
                                    if (success) {
                                        commitInput.text = "";
                                        backendBridge.sendRequest("git.push", {"path": p.local_path, "project_id": p.id}, function(pushSuccess, pushData, pushErr) {
                                            if (pushSuccess) {
                                                toast.show("Committed and pushed successfully!", "success");
                                            } else {
                                                toast.show("Committed, but push failed: " + pushErr, "warning");
                                            }
                                            root.loadStatus();
                                            root.refreshRequested();
                                        });
                                    } else {
                                        toast.show("Commit failed: " + err, "error");
                                    }
                                });
                            }
                        }
                    }
                }
            }
        }

        // Right Panel: Diff Viewer
        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 8

            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: root.activeFilePath ? ("Diff: " + root.activeFilePath + (root.activeFileIsStaged ? " (Staged)" : " (Working Tree)")) : "File Diff Viewer"
                    color: themeManager.textPrimary
                    font.pixelSize: 14
                    font.weight: Font.Bold
                }

                Item { Layout.fillWidth: true }
            }

            DiffViewer {
                Layout.fillWidth: true
                Layout.fillHeight: true
                diffData: root.activeDiffData
            }
        }
    }
}
