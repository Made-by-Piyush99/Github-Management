import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

Item {
    id: root

    property string projectId: ""
    property var projectDetails: null
    property int currentSubTab: 0 // 0: Overview, 1: Reports, 2: Changes, 3: Commits, 4: Branches, 5: Remote
    property bool loading: false

    signal backRequested()
    signal refreshRequested()

    function loadProject() {
        if (!projectId) return;
        loading = true;
        backendBridge.sendRequest("projects.get_details", {"id": projectId}, function(success, data, err) {
            loading = false;
            if (success) {
                projectDetails = data;
            } else {
                toast.show("Failed to load project: " + err, "error");
            }
        });
    }

    onProjectIdChanged: {
        loadProject();
    }

    Component.onCompleted: {
        loadProject();
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // Sub-header with Back Button, Project Title, and Subtabs
        Rectangle {
            Layout.fillWidth: true
            height: 60
            color: themeManager.bgSecondary
            border.color: themeManager.borderPrimary
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 20
                anchors.rightMargin: 20
                spacing: 16

                ActionButton {
                    text: "Back"
                    iconText: "←"
                    btnStyle: "subtle"
                    small: true
                    onClicked: root.backRequested()
                }

                Text {
                    text: root.projectDetails ? root.projectDetails.project.name : "Project Details"
                    color: themeManager.textPrimary
                    font.pixelSize: 16
                    font.weight: Font.Bold
                }

                Item { Layout.fillWidth: true }

                // Sub-tabs navigation buttons
                Row {
                    spacing: 4

                    Repeater {
                        model: ["Overview", "Health Report", "Changes", "Commits", "Branches", "Remote"]

                        Rectangle {
                            height: 32
                            width: tabLabel.implicitWidth + 24
                            radius: 6
                            color: root.currentSubTab === index ? themeManager.accentMuted : (tabMouse.containsMouse ? themeManager.bgCardHover : "transparent")

                            Text {
                                id: tabLabel
                                anchors.centerIn: parent
                                text: modelData
                                color: root.currentSubTab === index ? themeManager.accent : themeManager.textSecondary
                                font.pixelSize: 12
                                font.weight: root.currentSubTab === index ? Font.DemiBold : Font.Normal
                            }

                            MouseArea {
                                id: tabMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.currentSubTab = index
                            }
                        }
                    }
                }
            }
        }

        // Subtab Content Stack
        StackLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            currentIndex: root.currentSubTab

            // ==========================
            // 0: Overview Sub-tab
            // ==========================
            ScrollView {
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    width: parent.width
                    anchors.margins: 24
                    spacing: 20

                    // Overview Card
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: overCol.implicitHeight + 36
                        radius: 8
                        color: themeManager.bgCard
                        border.color: themeManager.borderPrimary
                        border.width: 1

                        ColumnLayout {
                            id: overCol
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 16

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                Column {
                                    spacing: 4
                                    Text {
                                        text: root.projectDetails ? root.projectDetails.project.name : ""
                                        color: themeManager.textPrimary
                                        font.pixelSize: 16
                                        font.weight: Font.Bold
                                    }
                                    Text {
                                        text: root.projectDetails ? root.projectDetails.project.local_path : ""
                                        color: themeManager.textMuted
                                        font.pixelSize: 12
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                StatusBadge {
                                    status: root.projectDetails && root.projectDetails.repo_info ? root.projectDetails.repo_info.status : "Unknown"
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 1
                                color: themeManager.borderPrimary
                            }

                            // Detail Grid
                            GridLayout {
                                Layout.fillWidth: true
                                columns: 2
                                rowSpacing: 10
                                columnSpacing: 20

                                Text { text: "Current Branch:"; color: themeManager.textMuted; font.pixelSize: 12 }
                                Text {
                                    text: root.projectDetails && root.projectDetails.repo_info ? root.projectDetails.repo_info.current_branch : "None"
                                    color: themeManager.textPrimary
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }

                                Text { text: "Remote URL:"; color: themeManager.textMuted; font.pixelSize: 12 }
                                Text {
                                    text: root.projectDetails && root.projectDetails.repo_info ? (root.projectDetails.repo_info.primary_remote_url || "No remote configured") : "None"
                                    color: themeManager.accent
                                    font.pixelSize: 12
                                }

                                Text { text: "Tracking Status:"; color: themeManager.textMuted; font.pixelSize: 12 }
                                Text {
                                    text: {
                                        if (!root.projectDetails || !root.projectDetails.repo_info) return "Unknown";
                                        var r = root.projectDetails.repo_info;
                                        return (r.ahead || 0) + " ahead, " + (r.behind || 0) + " behind " + (r.upstream || "upstream");
                                    }
                                    color: themeManager.textPrimary
                                    font.pixelSize: 12
                                }

                                Text { text: "Working Tree:"; color: themeManager.textMuted; font.pixelSize: 12 }
                                Text {
                                    text: {
                                        if (!root.projectDetails || !root.projectDetails.repo_info) return "Clean";
                                        var r = root.projectDetails.repo_info;
                                        return (r.uncommitted_count || 0) + " uncommitted (" + (r.staged_count || 0) + " staged, " + (r.modified_count || 0) + " modified)";
                                    }
                                    color: themeManager.textPrimary
                                    font.pixelSize: 12
                                }
                            }

                            // Quick Action Buttons
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                ActionButton {
                                    text: "Open Folder"
                                    iconText: "📁"
                                    btnStyle: "secondary"
                                    onClicked: backendBridge.openFolder(root.projectDetails.project.local_path)
                                }

                                ActionButton {
                                    text: "Fetch"
                                    iconText: "🔄"
                                    btnStyle: "secondary"
                                    onClicked: {
                                        backendBridge.sendRequest("git.fetch", {"path": root.projectDetails.project.local_path, "project_id": root.projectId}, function(s) {
                                            if (s) { toast.show("Fetch completed.", "success"); root.loadProject(); }
                                        });
                                    }
                                }

                                ActionButton {
                                    text: "Pull"
                                    iconText: "⬇️"
                                    btnStyle: "secondary"
                                    onClicked: {
                                        backendBridge.sendRequest("git.pull", {"path": root.projectDetails.project.local_path, "project_id": root.projectId}, function(s) {
                                            if (s) { toast.show("Pull completed.", "success"); root.loadProject(); }
                                        });
                                    }
                                }

                                ActionButton {
                                    text: "Push"
                                    iconText: "⬆️"
                                    btnStyle: "primary"
                                    onClicked: {
                                        backendBridge.sendRequest("git.push", {"path": root.projectDetails.project.local_path, "project_id": root.projectId}, function(s) {
                                            if (s) { toast.show("Push completed.", "success"); root.loadProject(); }
                                        });
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ==========================
            // 1: Health Report Sub-tab
            // ==========================
            ScrollView {
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    width: parent.width
                    anchors.margins: 24
                    spacing: 20

                    // Top Report Score Card & Recommendations
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: repCol.implicitHeight + 36
                        radius: 8
                        color: themeManager.bgCard
                        border.color: themeManager.borderPrimary
                        border.width: 1

                        ColumnLayout {
                            id: repCol
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 16

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 16

                                // Big Score Gauge / Circle
                                Rectangle {
                                    width: 80
                                    height: 80
                                    radius: 40
                                    color: themeManager.bgPrimary
                                    border.color: themeManager.accent
                                    border.width: 3

                                    Column {
                                        anchors.centerIn: parent
                                        spacing: 2
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: root.projectDetails && root.projectDetails.report ? ("" + root.projectDetails.report.health_score) : "0"
                                            color: themeManager.accent
                                            font.pixelSize: 22
                                            font.weight: Font.Bold
                                        }
                                        Text {
                                            anchors.horizontalCenter: parent.horizontalCenter
                                            text: root.projectDetails && root.projectDetails.report ? root.projectDetails.report.grade : ""
                                            color: themeManager.textSecondary
                                            font.pixelSize: 11
                                            font.weight: Font.DemiBold
                                        }
                                    }
                                }

                                Column {
                                    spacing: 4
                                    Text {
                                        text: "Repository Health Score"
                                        color: themeManager.textPrimary
                                        font.pixelSize: 16
                                        font.weight: Font.Bold
                                    }
                                    Text {
                                        text: "Calculated based on commit frequency, working tree hygiene, upstream synchronization, and conflict status."
                                        color: themeManager.textSecondary
                                        font.pixelSize: 12
                                        Layout.maximumWidth: 500
                                        wrapMode: Text.WordWrap
                                    }
                                }

                                Item { Layout.fillWidth: true }

                                ActionButton {
                                    text: "Export Report CSV"
                                    iconText: "📊"
                                    btnStyle: "secondary"
                                    small: true
                                    onClicked: {
                                        var p = backendBridge.selectSaveFile("Save Health Report", "health_report.csv", "CSV Files (*.csv)");
                                        if (p) {
                                            backendBridge.sendRequest("reports.export", {"project_id": root.projectId, "format": "csv", "output_path": p}, function(s) {
                                                if (s) toast.show("Exported report to CSV.", "success");
                                            });
                                        }
                                    }
                                }

                                ActionButton {
                                    text: "Export Report JSON"
                                    iconText: "📄"
                                    btnStyle: "secondary"
                                    small: true
                                    onClicked: {
                                        var p = backendBridge.selectSaveFile("Save Health Report", "health_report.json", "JSON Files (*.json)");
                                        if (p) {
                                            backendBridge.sendRequest("reports.export", {"project_id": root.projectId, "format": "json", "output_path": p}, function(s) {
                                                if (s) toast.show("Exported report to JSON.", "success");
                                            });
                                        }
                                    }
                                }
                            }

                            // Commit Activity Trend Bar Chart
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "14-DAY COMMIT ACTIVITY TREND"
                                    color: themeManager.textMuted
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 100
                                    radius: 6
                                    color: themeManager.bgPrimary
                                    border.color: themeManager.borderPrimary
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 6

                                        Repeater {
                                            model: (root.projectDetails && root.projectDetails.report) ? root.projectDetails.report.activity_chart : []

                                            Column {
                                                Layout.fillWidth: true
                                                Layout.fillHeight: true
                                                spacing: 4

                                                Rectangle {
                                                    width: parent.width
                                                    height: Math.max(4, Math.min(60, modelData.count * 12))
                                                    radius: 2
                                                    color: modelData.count > 0 ? themeManager.accent : themeManager.borderPrimary
                                                    anchors.bottom: parent.bottom
                                                }

                                                Text {
                                                    anchors.horizontalCenter: parent.horizontalCenter
                                                    text: modelData.date.substring(5)
                                                    color: themeManager.textMuted
                                                    font.pixelSize: 9
                                                }
                                            }
                                        }
                                    }
                                }
                            }

                            // Recommendations List
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "ACTIONABLE RECOMMENDATIONS"
                                    color: themeManager.textMuted
                                    font.pixelSize: 11
                                    font.weight: Font.Bold
                                }

                                Repeater {
                                    model: (root.projectDetails && root.projectDetails.report) ? root.projectDetails.report.recommendations : []

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 38
                                        radius: 6
                                        color: themeManager.bgPrimary
                                        border.color: themeManager.borderPrimary
                                        border.width: 1

                                        RowLayout {
                                            anchors.fill: parent
                                            anchors.leftMargin: 12
                                            anchors.rightMargin: 12
                                            spacing: 10

                                            Text { text: "💡"; font.pixelSize: 13 }
                                            Text {
                                                text: modelData
                                                color: themeManager.textPrimary
                                                font.pixelSize: 12
                                                Layout.fillWidth: true
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ==========================
            // 2: Changes Sub-tab
            // ==========================
            ChangesView {
                selectedProjectId: root.projectId
                onRefreshRequested: root.loadProject()
            }

            // ==========================
            // 3: Commits Sub-tab
            // ==========================
            ScrollView {
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    width: parent.width
                    anchors.margins: 24
                    spacing: 12

                    Text {
                        text: "COMMIT HISTORY"
                        color: themeManager.textMuted
                        font.pixelSize: 11
                        font.weight: Font.Bold
                    }

                    Repeater {
                        model: root.projectDetails ? root.projectDetails.commits : []

                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: cCol.implicitHeight + 20
                            radius: 6
                            color: themeManager.bgCard
                            border.color: themeManager.borderPrimary
                            border.width: 1

                            ColumnLayout {
                                id: cCol
                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 4

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Rectangle {
                                        height: 20
                                        width: hashText.implicitWidth + 8
                                        radius: 4
                                        color: themeManager.accentMuted
                                        Text {
                                            id: hashText
                                            anchors.centerIn: parent
                                            text: modelData.short_hash
                                            color: themeManager.accent
                                            font.family: "Consolas, monospace"
                                            font.pixelSize: 11
                                            font.weight: Font.Bold
                                        }
                                    }

                                    Text {
                                        text: modelData.subject
                                        color: themeManager.textPrimary
                                        font.pixelSize: 13
                                        font.weight: Font.DemiBold
                                        Layout.fillWidth: true
                                    }

                                    Text {
                                        text: Qt.formatDateTime(new Date(modelData.date), "yyyy-MM-dd hh:mm")
                                        color: themeManager.textMuted
                                        font.pixelSize: 11
                                    }
                                }

                                Text {
                                    text: "Author: " + modelData.author_name + " <" + modelData.author_email + ">"
                                    color: themeManager.textSecondary
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }
                }
            }

            // ==========================
            // 4: Branches Sub-tab
            // ==========================
            BranchesView {
                selectedProjectId: root.projectId
                onRefreshRequested: root.loadProject()
            }

            // ==========================
            // 5: Remote Sub-tab
            // ==========================
            ScrollView {
                contentWidth: availableWidth
                clip: true

                ColumnLayout {
                    width: parent.width
                    anchors.margins: 24
                    spacing: 20

                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: remCol.implicitHeight + 36
                        radius: 8
                        color: themeManager.bgCard
                        border.color: themeManager.borderPrimary
                        border.width: 1

                        ColumnLayout {
                            id: remCol
                            anchors.fill: parent
                            anchors.margins: 20
                            spacing: 16

                            Text {
                                text: "REMOTE CONFIGURATION"
                                color: themeManager.textMuted
                                font.pixelSize: 11
                                font.weight: Font.Bold
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 38
                                    radius: 6
                                    color: themeManager.bgInput
                                    border.color: themeManager.borderPrimary
                                    border.width: 1

                                    TextField {
                                        id: remoteUrlInput
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        color: themeManager.textPrimary
                                        font.pixelSize: 12
                                        text: root.projectDetails && root.projectDetails.repo_info ? root.projectDetails.repo_info.primary_remote_url : ""
                                        placeholderText: "https://github.com/owner/repository.git"
                                        background: null
                                    }
                                }

                                ActionButton {
                                    text: "Update Remote"
                                    iconText: "🔗"
                                    btnStyle: "primary"
                                    onClicked: {
                                        var url = remoteUrlInput.text.trim();
                                        backendBridge.sendRequest("github.link_repo", {"project_id": root.projectId, "remote_url": url}, function(s, d, err) {
                                            if (s) {
                                                toast.show("Remote URL updated.", "success");
                                                root.loadProject();
                                            } else {
                                                toast.show("Failed: " + err, "error");
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
}
