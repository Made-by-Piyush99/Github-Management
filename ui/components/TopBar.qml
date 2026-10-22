import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property string title: "Dashboard"
    property string searchQuery: ""
    property var githubUser: null
    property bool isRefreshing: false

    signal searchChanged(string query)
    signal refreshClicked()
    signal githubPillClicked()
    signal createRepoClicked()

    height: 56
    color: themeManager.bgSecondary
    border.color: themeManager.borderPrimary
    border.width: 1

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 20
        spacing: 16

        // Title / Breadcrumb
        Text {
            text: root.title
            color: themeManager.textPrimary
            font.pixelSize: 17
            font.weight: Font.Bold
        }

        Item { Layout.preferredWidth: 20 }

        // Global Search Bar
        Rectangle {
            Layout.preferredWidth: 320
            Layout.maximumWidth: 400
            height: 34
            radius: 6
            color: themeManager.bgInput
            border.color: searchInput.activeFocus ? themeManager.accent : themeManager.borderPrimary
            border.width: 1

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 10
                spacing: 8

                Text {
                    text: "🔍"
                    font.pixelSize: 12
                    color: themeManager.textMuted
                }

                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: themeManager.textPrimary
                    font.pixelSize: 13
                    clip: true
                    selectByMouse: true
                    onTextChanged: root.searchChanged(text)

                    Text {
                        anchors.fill: parent
                        visible: !searchInput.text && !searchInput.activeFocus
                        text: "Search projects, branches, remotes..."
                        color: themeManager.textMuted
                        font.pixelSize: 13
                    }
                }

                Text {
                    visible: searchInput.text !== ""
                    text: "✕"
                    color: themeManager.textMuted
                    font.pixelSize: 12

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            searchInput.text = "";
                            root.searchChanged("");
                        }
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // Create New Repository Button (Visible across all tabs!)
        ActionButton {
            text: "New Repo"
            iconText: "➕"
            btnStyle: "primary"
            onClicked: root.createRepoClicked()
        }

        // Refresh All Button
        ActionButton {
            text: "Refresh"
            iconText: "🔄"
            btnStyle: "subtle"
            busy: root.isRefreshing
            onClicked: root.refreshClicked()
        }

        // GitHub Account Pill
        Rectangle {
            height: 32
            width: ghRow.implicitWidth + 20
            radius: 16
            color: ghMouse.containsMouse ? themeManager.bgCardHover : themeManager.bgCard
            border.color: themeManager.borderPrimary
            border.width: 1

            Row {
                id: ghRow
                anchors.centerIn: parent
                spacing: 6

                Text {
                    text: "🐙"
                    font.pixelSize: 14
                    anchors.verticalCenter: parent.verticalCenter
                }

                Rectangle {
                    width: 6
                    height: 6
                    radius: 3
                    color: root.githubUser ? themeManager.success : themeManager.textMuted
                    anchors.verticalCenter: parent.verticalCenter
                }

                Text {
                    text: root.githubUser ? ("@" + root.githubUser.login) : "Connect GitHub"
                    color: root.githubUser ? themeManager.textPrimary : themeManager.textSecondary
                    font.pixelSize: 12
                    font.weight: Font.Medium
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            MouseArea {
                id: ghMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: root.githubPillClicked()
            }
        }

        // Theme Toggle (Moon / Sun)
        Rectangle {
            width: 32
            height: 32
            radius: 6
            color: themeMouse.containsMouse ? themeManager.bgCardHover : "transparent"
            border.color: themeManager.borderPrimary
            border.width: 1

            Text {
                anchors.centerIn: parent
                text: themeManager.isDark ? "☀️" : "🌙"
                font.pixelSize: 14
            }

            MouseArea {
                id: themeMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: themeManager.toggleTheme()
            }
        }
    }
}
