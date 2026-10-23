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

    function focusSearch() {
        searchInput.forceActiveFocus();
        searchInput.selectAll();
    }

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

        // Global Search Bar - Translucent Glassmorphism
        Rectangle {
            id: searchContainer
            Layout.preferredWidth: 340
            Layout.maximumWidth: 420
            height: 36
            radius: 8

            color: {
                if (searchInput.activeFocus) {
                    return themeManager.isDark ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.05);
                }
                if (searchMouse.containsMouse) {
                    return themeManager.isDark ? Qt.rgba(255, 255, 255, 0.05) : Qt.rgba(0, 0, 0, 0.035);
                }
                return themeManager.isDark ? Qt.rgba(255, 255, 255, 0.03) : Qt.rgba(0, 0, 0, 0.02);
            }

            border.color: {
                if (searchInput.activeFocus) return themeManager.accent;
                if (searchMouse.containsMouse) return themeManager.borderSecondary;
                return themeManager.isDark ? Qt.rgba(255, 255, 255, 0.1) : themeManager.borderPrimary;
            }
            border.width: 1

            Behavior on color { ColorAnimation { duration: 120 } }
            Behavior on border.color { ColorAnimation { duration: 120 } }

            MouseArea {
                id: searchMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.IBeamCursor
                onClicked: searchInput.forceActiveFocus()
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 10
                spacing: 8

                AppIcon {
                    name: "search"
                    size: 14
                    color: searchInput.activeFocus ? themeManager.accent : themeManager.textMuted
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
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                // Keyboard shortcut hint pill (Ctrl+K)
                Rectangle {
                    visible: searchInput.text === ""
                    height: 20
                    width: kbdLabel.implicitWidth + 10
                    radius: 4
                    color: themeManager.isDark ? Qt.rgba(255, 255, 255, 0.06) : Qt.rgba(0, 0, 0, 0.05)
                    border.color: themeManager.isDark ? Qt.rgba(255, 255, 255, 0.08) : Qt.rgba(0, 0, 0, 0.08)
                    border.width: 1

                    Text {
                        id: kbdLabel
                        anchors.centerIn: parent
                        text: "Ctrl K"
                        color: themeManager.textMuted
                        font.pixelSize: 10
                        font.weight: Font.DemiBold
                    }
                }

                // Clear button
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
            iconName: "plus"
            btnStyle: "primary"
            onClicked: root.createRepoClicked()
        }

        // Refresh All Button
        ActionButton {
            text: "Refresh"
            iconName: "refresh"
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
                spacing: 8

                AppIcon {
                    name: "github"
                    size: 15
                    color: root.githubUser ? themeManager.accent : themeManager.textSecondary
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

            AppIcon {
                anchors.centerIn: parent
                name: themeManager.isDark ? "sun" : "moon"
                size: 15
                color: themeManager.textSecondary
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
