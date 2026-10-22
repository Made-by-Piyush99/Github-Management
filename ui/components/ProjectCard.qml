import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property var projectData: ({})
    signal openDetails(string projectId)
    signal quickAction(string action, var project)

    implicitWidth: 600
    implicitHeight: 140
    radius: 8
    color: mouseArea.containsMouse ? themeManager.bgCardHover : themeManager.bgCard
    border.color: mouseArea.containsMouse ? themeManager.borderSecondary : themeManager.borderPrimary
    border.width: 1

    Behavior on color { ColorAnimation { duration: 120 } }
    Behavior on border.color { ColorAnimation { duration: 120 } }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            root.openDetails(projectData.id);
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 8

        // Top Row: Name, Path, Branch, Status Badge, Pin
        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Text {
                text: projectData.name || "Untitled Project"
                color: themeManager.textPrimary
                font.pixelSize: 15
                font.weight: Font.Bold
            }

            Rectangle {
                visible: !!projectData.current_branch
                height: 22
                width: branchLabel.implicitWidth + 14
                radius: 4
                color: themeManager.bgPrimary
                border.color: themeManager.borderPrimary
                border.width: 1

                Row {
                    anchors.centerIn: parent
                    spacing: 4
                    Text { text: "🌿"; font.pixelSize: 10; anchors.verticalCenter: parent.verticalCenter }
                    Text {
                        id: branchLabel
                        text: projectData.current_branch || ""
                        color: themeManager.textSecondary
                        font.pixelSize: 11
                        font.weight: Font.Medium
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }
            }

            StatusBadge {
                status: projectData.status || "Unknown"
                small: true
            }

            Item { Layout.fillWidth: true }

            // Uncommitted badge
            Rectangle {
                visible: (projectData.uncommitted_count || 0) > 0
                height: 20
                width: uncommLabel.implicitWidth + 10
                radius: 10
                color: Qt.rgba(themeManager.warning.r, themeManager.warning.g, themeManager.warning.b, 0.15)
                border.color: themeManager.warning
                border.width: 1

                Text {
                    id: uncommLabel
                    anchors.centerIn: parent
                    text: (projectData.uncommitted_count || 0) + " uncommitted"
                    color: themeManager.warning
                    font.pixelSize: 10
                    font.weight: Font.Medium
                }
            }

            // Ahead / Behind badges
            Rectangle {
                visible: (projectData.ahead || 0) > 0
                height: 20
                width: aheadLabel.implicitWidth + 10
                radius: 10
                color: Qt.rgba(themeManager.accent.r, themeManager.accent.g, themeManager.accent.b, 0.15)
                border.color: themeManager.accent
                border.width: 1

                Text {
                    id: aheadLabel
                    anchors.centerIn: parent
                    text: "↑ " + (projectData.ahead || 0) + " ahead"
                    color: themeManager.accent
                    font.pixelSize: 10
                    font.weight: Font.Medium
                }
            }

            Rectangle {
                visible: (projectData.behind || 0) > 0
                height: 20
                width: behindLabel.implicitWidth + 10
                radius: 10
                color: Qt.rgba(themeManager.warning.r, themeManager.warning.g, themeManager.warning.b, 0.15)
                border.color: themeManager.warning
                border.width: 1

                Text {
                    id: behindLabel
                    anchors.centerIn: parent
                    text: "↓ " + (projectData.behind || 0) + " behind"
                    color: themeManager.warning
                    font.pixelSize: 10
                    font.weight: Font.Medium
                }
            }

            Text {
                visible: !!projectData.is_pinned
                text: "📌"
                font.pixelSize: 12
            }
        }

        // Middle Row: Path, Remote URL, Last commit message
        RowLayout {
            Layout.fillWidth: true
            spacing: 12

            Text {
                text: "📁 " + (projectData.local_path || "")
                color: themeManager.textMuted
                font.pixelSize: 11
                elide: Text.ElideMiddle
                Layout.maximumWidth: 280
            }

            Text {
                visible: !!projectData.git_remote
                text: "🔗 " + (projectData.git_remote || "")
                color: themeManager.accent
                font.pixelSize: 11
                elide: Text.ElideMiddle
                Layout.maximumWidth: 240
            }

            Item { Layout.fillWidth: true }

            Text {
                text: projectData.last_commit_subject ? ("Latest: \"" + projectData.last_commit_subject + "\"") : "No commits yet"
                color: themeManager.textSecondary
                font.pixelSize: 11
                elide: Text.ElideRight
                Layout.maximumWidth: 320
            }
        }

        // Divider
        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: themeManager.borderPrimary
        }

        // Bottom Row: Quick Actions Buttons
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                text: projectData.last_successful_push ? ("Last Push: " + Qt.formatDateTime(new Date(projectData.last_successful_push), "MM-dd hh:mm")) : "Never pushed"
                color: themeManager.textMuted
                font.pixelSize: 11
            }

            Item { Layout.fillWidth: true }

            ActionButton {
                text: "Folder"
                iconText: "📁"
                btnStyle: "subtle"
                small: true
                onClicked: root.quickAction("folder", projectData)
            }

            ActionButton {
                text: "Changes"
                iconText: "📝"
                btnStyle: "subtle"
                small: true
                onClicked: root.quickAction("changes", projectData)
            }

            ActionButton {
                text: "Pull"
                iconText: "⬇️"
                btnStyle: "subtle"
                small: true
                onClicked: root.quickAction("pull", projectData)
            }

            ActionButton {
                text: "Push"
                iconText: "⬆️"
                btnStyle: "subtle"
                small: true
                onClicked: root.quickAction("push", projectData)
            }

            ActionButton {
                text: "Branch"
                iconText: "🌿"
                btnStyle: "subtle"
                small: true
                onClicked: root.quickAction("branch", projectData)
            }

            ActionButton {
                text: "Report"
                iconText: "📊"
                btnStyle: "subtle"
                small: true
                onClicked: root.quickAction("report", projectData)
            }
        }
    }
}
