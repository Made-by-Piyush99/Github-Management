import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property int activeTab: 0
    property string gitVersion: "Git"
    property bool backendConnected: true

    signal tabSelected(int index)

    width: 230
    color: themeManager.bgSecondary
    border.color: themeManager.borderPrimary
    border.width: 1

    readonly property var sections: [
        {
            category: "WORKSPACE",
            items: [
                { index: 0, title: "Dashboard", icon: "dashboard" },
                { index: 1, title: "Projects", icon: "project" },
                { index: 2, title: "Repositories", icon: "repo" }
            ]
        },
        {
            category: "GIT WORKFLOW",
            items: [
                { index: 3, title: "Branches", icon: "branch" },
                { index: 4, title: "Changes & Commits", icon: "diff" },
                { index: 5, title: "Activity & Reports", icon: "activity" }
            ]
        },
        {
            category: "INTEGRATIONS & TOOLS",
            items: [
                { index: 6, title: "GitHub", icon: "github" },
                { index: 7, title: "Guide & Info", icon: "guide" },
                { index: 8, title: "Settings", icon: "settings" }
            ]
        }
    ]

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // App Logo & Header
        Rectangle {
            Layout.fillWidth: true
            height: 64
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                Rectangle {
                    width: 34
                    height: 34
                    radius: 8
                    color: Qt.rgba(56/255, 189/255, 248/255, 0.15)
                    border.color: Qt.rgba(56/255, 189/255, 248/255, 0.4)
                    border.width: 1

                    AppIcon {
                        anchors.centerIn: parent
                        name: "repo"
                        size: 18
                        color: themeManager.accent
                    }
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: "DevSync Studio"
                        color: themeManager.textPrimary
                        font.pixelSize: 14
                        font.weight: Font.DemiBold
                        font.letterSpacing: 0.3
                    }

                    Text {
                        text: "Git & GitHub Architect"
                        color: themeManager.textMuted
                        font.pixelSize: 10
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

        // Navigation Items
        ScrollView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            Column {
                width: root.width
                spacing: 14
                topPadding: 12
                bottomPadding: 12

                Repeater {
                    model: root.sections

                    Column {
                        width: root.width
                        spacing: 2

                        // Section Category Header
                        Text {
                            text: modelData.category
                            color: themeManager.textMuted
                            font.pixelSize: 10
                            font.weight: Font.DemiBold
                            font.letterSpacing: 1.0
                            leftPadding: 20
                            bottomPadding: 4
                        }

                        Repeater {
                            model: modelData.items

                            Rectangle {
                                id: navBtn
                                width: root.width - 20
                                height: 36
                                anchors.horizontalCenter: parent.horizontalCenter
                                radius: 6

                                property bool isActive: root.activeTab === modelData.index
                                property bool isHovered: mouseArea.containsMouse

                                color: isActive
                                       ? themeManager.accentMuted
                                       : (isHovered ? themeManager.bgCardHover : "transparent")

                                Behavior on color { ColorAnimation { duration: 100 } }

                                // Left active indicator pill
                                Rectangle {
                                    visible: navBtn.isActive
                                    width: 3
                                    height: 18
                                    radius: 1.5
                                    color: themeManager.accent
                                    anchors.left: parent.left
                                    anchors.leftMargin: 3
                                    anchors.verticalCenter: parent.verticalCenter
                                }

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 14
                                    anchors.rightMargin: 12
                                    spacing: 10

                                    AppIcon {
                                        name: modelData.icon
                                        size: 16
                                        color: navBtn.isActive
                                               ? themeManager.accent
                                               : (navBtn.isHovered ? themeManager.textPrimary : themeManager.textSecondary)
                                    }

                                    Text {
                                        text: modelData.title
                                        color: navBtn.isActive
                                               ? themeManager.accent
                                               : (navBtn.isHovered ? themeManager.textPrimary : themeManager.textSecondary)
                                        font.pixelSize: 13
                                        font.weight: navBtn.isActive ? Font.Medium : Font.Normal
                                        Layout.fillWidth: true
                                    }
                                }

                                MouseArea {
                                    id: mouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.tabSelected(modelData.index)
                                }
                            }
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

        // Footer status bar
        Rectangle {
            Layout.fillWidth: true
            height: 52
            color: "transparent"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 8

                // Backend status indicator
                Rectangle {
                    width: 7
                    height: 7
                    radius: 3.5
                    color: root.backendConnected ? themeManager.success : themeManager.danger
                }

                Text {
                    text: root.backendConnected ? "Engine Active" : "Offline"
                    color: themeManager.textSecondary
                    font.pixelSize: 11
                    Layout.fillWidth: true
                }

                // Git version tag
                Rectangle {
                    height: 20
                    width: gitLabel.implicitWidth + 12
                    radius: 4
                    color: themeManager.bgPrimary
                    border.color: themeManager.borderPrimary
                    border.width: 1

                    Text {
                        id: gitLabel
                        anchors.centerIn: parent
                        text: root.gitVersion
                        color: themeManager.textMuted
                        font.pixelSize: 10
                    }
                }
            }
        }
    }
}
