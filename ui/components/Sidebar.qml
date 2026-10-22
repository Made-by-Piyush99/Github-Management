import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property int activeTab: 0
    property string gitVersion: "Git"
    property bool backendConnected: true

    signal tabSelected(int index)

    width: 220
    color: themeManager.bgSecondary
    border.color: themeManager.borderPrimary
    border.width: 1

    readonly property var navItems: [
        { title: "Dashboard", icon: "📊" },
        { title: "Projects", icon: "📁" },
        { title: "Repositories", icon: "📦" },
        { title: "Branches", icon: "🌿" },
        { title: "Changes & Commits", icon: "📝" },
        { title: "Activity & Reports", icon: "📜" },
        { title: "GitHub", icon: "🐙" },
        { title: "Guide & Info", icon: "📖" },
        { title: "Settings", icon: "⚙️" }
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
                spacing: 10

                Rectangle {
                    width: 32
                    height: 32
                    radius: 8
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: themeManager.accent }
                        GradientStop { position: 1.0; color: Qt.darker(themeManager.accent, 1.4) }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "⚡"
                        font.pixelSize: 16
                        color: "#FFFFFF"
                    }
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 1

                    Text {
                        text: "DevSync Studio"
                        color: themeManager.textPrimary
                        font.pixelSize: 14
                        font.weight: Font.Bold
                    }

                    Text {
                        text: "Project & Git Manager"
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
                spacing: 4
                topPadding: 12
                bottomPadding: 12

                Repeater {
                    model: root.navItems

                    Rectangle {
                        id: navBtn
                        width: root.width - 20
                        height: 40
                        anchors.horizontalCenter: parent.horizontalCenter
                        radius: 6

                        property bool isActive: root.activeTab === index
                        property bool isHovered: mouseArea.containsMouse

                        color: isActive
                               ? themeManager.accentMuted
                               : (isHovered ? themeManager.bgCardHover : "transparent")

                        Behavior on color { ColorAnimation { duration: 100 } }

                        // Left active indicator pill
                        Rectangle {
                            visible: navBtn.isActive
                            width: 3
                            height: 20
                            radius: 1.5
                            color: themeManager.accent
                            anchors.left: parent.left
                            anchors.leftMargin: 4
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 16
                            anchors.rightMargin: 12
                            spacing: 12

                            Text {
                                text: modelData.icon
                                font.pixelSize: 16
                            }

                            Text {
                                text: modelData.title
                                color: navBtn.isActive
                                       ? themeManager.accent
                                       : (navBtn.isHovered ? themeManager.textPrimary : themeManager.textSecondary)
                                font.pixelSize: 13
                                font.weight: navBtn.isActive ? Font.DemiBold : Font.Normal
                                Layout.fillWidth: true
                            }
                        }

                        MouseArea {
                            id: mouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: root.tabSelected(index)
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
                    width: 8
                    height: 8
                    radius: 4
                    color: root.backendConnected ? themeManager.success : themeManager.danger
                }

                Text {
                    text: root.backendConnected ? "Connected" : "Reconnecting..."
                    color: themeManager.textSecondary
                    font.pixelSize: 11
                    Layout.fillWidth: true
                }

                // Git version tag
                Rectangle {
                    height: 20
                    width: gitLabel.implicitWidth + 10
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
