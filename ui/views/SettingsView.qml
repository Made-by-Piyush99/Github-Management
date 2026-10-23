import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

ScrollView {
    id: root

    property var currentSettings: ({})
    property var sysInfo: ({})

    contentWidth: availableWidth
    clip: true

    function loadSettings() {
        backendBridge.sendRequest("settings.get_all", {}, function(success, data, err) {
            if (success) {
                currentSettings = data;
                gitPathField.text = data.git_path || "";
                apiUrlField.text = data.github_api_url || "https://api.github.com";
                refreshSlider.value = data.refresh_interval || 30;
                confirmToggle.checked = data.confirm_destructive !== false;
            }
        });

        backendBridge.sendRequest("system.info", {}, function(success, data, err) {
            if (success) {
                sysInfo = data;
            }
        });
    }

    Component.onCompleted: {
        loadSettings();
    }

    ColumnLayout {
        width: parent.width
        anchors.margins: 24
        spacing: 24

        // Header
        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2
            Text {
                text: "Application Settings"
                color: themeManager.textPrimary
                font.pixelSize: 18
                font.weight: Font.Bold
            }
            Text {
                text: "Configure Git environment, GitHub endpoints, preferences, and diagnostics."
                color: themeManager.textSecondary
                font.pixelSize: 12
            }
        }

        // Appearance Card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: appCol.implicitHeight + 32
            radius: 8
            color: themeManager.bgCard
            border.color: themeManager.borderPrimary
            border.width: 1

            ColumnLayout {
                id: appCol
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                Text {
                    text: "APPEARANCE & THEME"
                    color: themeManager.textMuted
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ActionButton {
                        text: "Dark Theme"
                        iconName: "moon"
                        btnStyle: themeManager.isDark ? "primary" : "secondary"
                        onClicked: {
                            themeManager.setIsDark(true);
                            backendBridge.sendRequest("settings.set", {"settings": {"theme": "dark"}});
                        }
                    }

                    ActionButton {
                        text: "Light Theme"
                        iconName: "sun"
                        btnStyle: !themeManager.isDark ? "primary" : "secondary"
                        onClicked: {
                            themeManager.setIsDark(false);
                            backendBridge.sendRequest("settings.set", {"settings": {"theme": "light"}});
                        }
                    }

                    Item { Layout.fillWidth: true }
                }
            }
        }

        // Git Environment Card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: gitCol.implicitHeight + 32
            radius: 8
            color: themeManager.bgCard
            border.color: themeManager.borderPrimary
            border.width: 1

            ColumnLayout {
                id: gitCol
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                Text {
                    text: "GIT ENVIRONMENT"
                    color: themeManager.textMuted
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                Text {
                    text: "Detected: " + (sysInfo.git_version || "Checking...") + " (" + (sysInfo.git_path || "") + ")"
                    color: themeManager.textSecondary
                    font.pixelSize: 12
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: 7
                        color: themeManager.isDark ? Qt.rgba(255, 255, 255, 0.04) : themeManager.bgInput
                        border.color: gitPathField.activeFocus ? themeManager.accent : (themeManager.isDark ? Qt.rgba(255, 255, 255, 0.1) : themeManager.borderPrimary)
                        border.width: 1

                        TextField {
                            id: gitPathField
                            anchors.fill: parent
                            anchors.margins: 8
                            color: themeManager.textPrimary
                            font.pixelSize: 12
                            placeholderText: "Custom Git executable path (optional)..."
                            background: null
                        }
                    }

                    ActionButton {
                        text: "Save Path"
                        iconName: "check"
                        btnStyle: "primary"
                        onClicked: {
                            backendBridge.sendRequest("settings.set", {"settings": {"git_path": gitPathField.text.trim()}}, function(s) {
                                if (s) {
                                    toast.show("Git path updated.", "success");
                                    root.loadSettings();
                                }
                            });
                        }
                    }
                }
            }
        }

        // GitHub API Card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: ghCol.implicitHeight + 32
            radius: 8
            color: themeManager.bgCard
            border.color: themeManager.borderPrimary
            border.width: 1

            ColumnLayout {
                id: ghCol
                anchors.fill: parent
                anchors.margins: 20
                spacing: 14

                Text {
                    text: "GITHUB API & CLASSIC TOKEN"
                    color: themeManager.textMuted
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: "Need a GitHub Personal Access Token (Classic)?"
                        color: themeManager.textPrimary
                        font.pixelSize: 13
                        Layout.fillWidth: true
                    }

                    ActionButton {
                        text: "Generate Token on GitHub (All Scopes Pre-selected)"
                        iconName: "external"
                        btnStyle: "primary"
                        small: true
                        onClicked: backendBridge.openUrl("https://github.com/settings/tokens/new?description=DevSyncStudio_FullAccess&scopes=repo,workflow,write:packages,read:packages,delete:packages,admin:org,admin:public_key,admin:repo_hook,admin:org_hook,gist,notifications,user,delete_repo,write:discussion,admin:enterprise,audit_log,codespace,project,admin:gpg_key")
                    }
                }

                Text {
                    text: "Click the button above to open GitHub with ALL check boxes pre-selected automatically (repo, workflow, packages, admin, gist, notifications, user, etc.) for complete app management without permission errors."
                    color: themeManager.textSecondary
                    font.pixelSize: 11
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: themeManager.borderPrimary
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        height: 38
                        radius: 7
                        color: themeManager.isDark ? Qt.rgba(255, 255, 255, 0.04) : themeManager.bgInput
                        border.color: apiUrlField.activeFocus ? themeManager.accent : (themeManager.isDark ? Qt.rgba(255, 255, 255, 0.1) : themeManager.borderPrimary)
                        border.width: 1

                        TextField {
                            id: apiUrlField
                            anchors.fill: parent
                            anchors.margins: 8
                            color: themeManager.textPrimary
                            font.pixelSize: 12
                            placeholderText: "https://api.github.com or Enterprise endpoint"
                            background: null
                        }
                    }

                    ActionButton {
                        text: "Update Endpoint"
                        iconName: "check"
                        btnStyle: "secondary"
                        onClicked: {
                            backendBridge.sendRequest("settings.set", {"settings": {"github_api_url": apiUrlField.text.trim()}}, function(s) {
                                if (s) {
                                    toast.show("GitHub API endpoint updated.", "success");
                                    root.loadSettings();
                                }
                            });
                        }
                    }
                }
            }
        }

        // Preferences Card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: prefCol.implicitHeight + 32
            radius: 8
            color: themeManager.bgCard
            border.color: themeManager.borderPrimary
            border.width: 1

            ColumnLayout {
                id: prefCol
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                Text {
                    text: "GENERAL PREFERENCES"
                    color: themeManager.textMuted
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: "Confirm destructive operations (discard changes, branch deletion):"
                        color: themeManager.textPrimary
                        font.pixelSize: 13
                        Layout.fillWidth: true
                    }

                    CheckBox {
                        id: confirmToggle
                        checked: true
                        onToggled: {
                            backendBridge.sendRequest("settings.set", {"settings": {"confirm_destructive": checked}});
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: "Background auto-refresh interval: " + Math.round(refreshSlider.value) + " seconds"
                        color: themeManager.textPrimary
                        font.pixelSize: 13
                        Layout.fillWidth: true
                    }

                    Slider {
                        id: refreshSlider
                        from: 10
                        to: 120
                        stepSize: 5
                        value: 30
                        onMoved: {
                            backendBridge.sendRequest("settings.set", {"settings": {"refresh_interval": Math.round(value)}});
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: themeManager.borderPrimary
                }

                Text {
                    text: "Database: " + (sysInfo.database_path || "")
                    color: themeManager.textMuted
                    font.pixelSize: 11
                }
            }
        }
    }
}
