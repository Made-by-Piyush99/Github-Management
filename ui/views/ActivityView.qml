import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

ScrollView {
    id: root

    property string statusFilter: "all"
    property string selectedProjFilter: ""

    signal refreshRequested()

    contentWidth: availableWidth
    clip: true

    function loadActivity() {
        var args = {"limit": 100};
        if (root.statusFilter !== "all") {
            args["status"] = root.statusFilter;
        }
        if (root.selectedProjFilter) {
            args["project_id"] = root.selectedProjFilter;
        }

        backendBridge.sendRequest("activity.list", args, function(success, data, err) {
            if (success) {
                activityModel.setActivities(data || []);
            }
        });
    }

    Component.onCompleted: {
        loadActivity();
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
                    text: "Activity & Audit Log"
                    color: themeManager.textPrimary
                    font.pixelSize: 18
                    font.weight: Font.Bold
                }
                Text {
                    text: "Detailed execution history for Git and synchronization operations."
                    color: themeManager.textSecondary
                    font.pixelSize: 12
                }
            }

            Item { Layout.fillWidth: true }

            ActionButton {
                text: "Export CSV"
                iconName: "activity"
                btnStyle: "secondary"
                small: true
                onClicked: {
                    var savePath = backendBridge.selectSaveFile("Export Activity CSV", "devsync_activity.csv", "CSV Files (*.csv)");
                    if (savePath) {
                        backendBridge.sendRequest("activity.export", {"format": "csv", "output_path": savePath}, function(s, d, err) {
                            if (s) toast.show("Exported activity log to CSV.", "success");
                            else toast.show("Export failed: " + err, "error");
                        });
                    }
                }
            }

            ActionButton {
                text: "Export JSON"
                iconName: "diff"
                btnStyle: "secondary"
                small: true
                onClicked: {
                    var savePath = backendBridge.selectSaveFile("Export Activity JSON", "devsync_activity.json", "JSON Files (*.json)");
                    if (savePath) {
                        backendBridge.sendRequest("activity.export", {"format": "json", "output_path": savePath}, function(s, d, err) {
                            if (s) toast.show("Exported activity log to JSON.", "success");
                            else toast.show("Export failed: " + err, "error");
                        });
                    }
                }
            }

            ActionButton {
                text: "Refresh"
                iconName: "refresh"
                btnStyle: "subtle"
                small: true
                onClicked: root.loadActivity()
            }
        }

        // Filter Pills
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ActionButton {
                text: "All Events"
                btnStyle: root.statusFilter === "all" ? "primary" : "subtle"
                small: true
                onClicked: { root.statusFilter = "all"; root.loadActivity(); }
            }

            ActionButton {
                text: "Success"
                btnStyle: root.statusFilter === "success" ? "primary" : "subtle"
                small: true
                onClicked: { root.statusFilter = "success"; root.loadActivity(); }
            }

            ActionButton {
                text: "Failed"
                btnStyle: root.statusFilter === "failed" ? "primary" : "subtle"
                small: true
                onClicked: { root.statusFilter = "failed"; root.loadActivity(); }
            }
        }

        // Empty state
        Rectangle {
            visible: activityModel.count === 0
            Layout.fillWidth: true
            height: 180
            radius: 8
            color: themeManager.bgCard
            border.color: themeManager.borderPrimary
            border.width: 1

            Column {
                anchors.centerIn: parent
                spacing: 8

                AppIcon {
                    anchors.horizontalCenter: parent.horizontalCenter
                    name: "activity"
                    size: 28
                    color: themeManager.textMuted
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "No activity records found."
                    color: themeManager.textSecondary
                    font.pixelSize: 13
                }
            }
        }

        // Activity List
        ListView {
            visible: activityModel.count > 0
            Layout.fillWidth: true
            implicitHeight: contentHeight
            interactive: false
            spacing: 8
            model: activityModel

            delegate: Rectangle {
                width: ListView.view.width
                implicitHeight: itemCol.implicitHeight + 20
                radius: 6
                color: themeManager.bgCard
                border.color: themeManager.borderPrimary
                border.width: 1

                ColumnLayout {
                    id: itemCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        AppIcon {
                            name: model.status === "success" ? "check" : "trash"
                            size: 14
                            color: model.status === "success" ? themeManager.success : themeManager.danger
                        }

                        Text {
                            text: model.op_type.toUpperCase()
                            color: themeManager.textPrimary
                            font.pixelSize: 13
                            font.weight: Font.Bold
                        }

                        Text {
                            visible: !!model.project_name
                            text: "• " + model.project_name
                            color: themeManager.accent
                            font.pixelSize: 13
                        }

                        Item { Layout.fillWidth: true }

                        Text {
                            text: (model.duration_ms || 0) + " ms"
                            color: themeManager.textMuted
                            font.pixelSize: 11
                        }

                        Text {
                            text: Qt.formatDateTime(new Date(model.started_at), "yyyy-MM-dd hh:mm:ss")
                            color: themeManager.textMuted
                            font.pixelSize: 11
                        }
                    }

                    Text {
                        visible: !!model.error_message
                        text: "Error: " + model.error_message
                        color: themeManager.danger
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }
                }
            }
        }
    }
}
