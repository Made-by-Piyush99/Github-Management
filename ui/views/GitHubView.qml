import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

ScrollView {
    id: root

    property var userInfo: null
    property var rateLimit: null
    property bool isConnected: false
    property bool isTesting: false
    property var remoteRepos: []
    property bool showToken: false

    signal githubStatusChanged()

    contentWidth: availableWidth
    clip: true

    function checkConnection() {
        isTesting = true;
        backendBridge.sendRequest("github.test_connection", {}, function(success, data, err) {
            isTesting = false;
            if (success && data && data.connected) {
                isConnected = true;
                userInfo = data.user;
                rateLimit = data.rate_limit;
                loadRemoteRepos();
            } else {
                isConnected = false;
                userInfo = null;
                rateLimit = null;
                remoteRepos = [];
            }
            root.githubStatusChanged();
        });
    }

    function loadRemoteRepos() {
        backendBridge.sendRequest("github.list_repos", {}, function(success, data, err) {
            if (success && data) {
                remoteRepos = data.repositories || [];
            }
        });
    }

    Component.onCompleted: {
        checkConnection();
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
                text: "GitHub Integration"
                color: themeManager.textPrimary
                font.pixelSize: 18
                font.weight: Font.Bold
            }
            Text {
                text: "Connect your GitHub account using an OS-keyring secured Personal Access Token."
                color: themeManager.textSecondary
                font.pixelSize: 12
            }
        }

        // Account / Connection Status Card
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: connCol.implicitHeight + 36
            radius: 8
            color: themeManager.bgCard
            border.color: themeManager.borderPrimary
            border.width: 1

            ColumnLayout {
                id: connCol
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Rectangle {
                        width: 44
                        height: 44
                        radius: 22
                        color: themeManager.bgPrimary
                        border.color: themeManager.borderPrimary
                        border.width: 1

                        AppIcon {
                            anchors.centerIn: parent
                            name: "github"
                            size: 22
                            color: themeManager.accent
                        }
                    }

                    Column {
                        spacing: 2
                        Text {
                            text: root.isConnected && root.userInfo ? root.userInfo.name : "Not Connected"
                            color: themeManager.textPrimary
                            font.pixelSize: 15
                            font.weight: Font.Bold
                        }
                        Text {
                            text: root.isConnected && root.userInfo ? ("@" + root.userInfo.login + " • " + (root.userInfo.public_repos + root.userInfo.total_private_repos) + " repos") : "Configure GitHub access token below"
                            color: themeManager.textSecondary
                            font.pixelSize: 12
                        }
                    }

                    Item { Layout.fillWidth: true }

                    StatusBadge {
                        status: root.isConnected ? "Synced" : "Disconnected"
                    }
                }

                // Rate limit meter if connected
                RowLayout {
                    visible: root.isConnected && root.rateLimit !== null
                    Layout.fillWidth: true
                    spacing: 12

                    Text {
                        text: "API Rate Limit: " + (root.rateLimit ? root.rateLimit.remaining : 0) + " / " + (root.rateLimit ? root.rateLimit.limit : 0) + " remaining"
                        color: themeManager.textMuted
                        font.pixelSize: 11
                    }

                    Item { Layout.fillWidth: true }

                    ActionButton {
                        text: "Disconnect"
                        iconName: "trash"
                        btnStyle: "danger"
                        small: true
                        onClicked: {
                            confirmDialog.open(
                                "Disconnect GitHub Account",
                                "Are you sure you want to remove your GitHub credentials from the secure OS keyring?",
                                function() {
                                    backendBridge.sendRequest("github.delete_token", {}, function(s) {
                                        toast.show("GitHub account disconnected.", "info");
                                        root.checkConnection();
                                    });
                                },
                                "danger",
                                "Disconnect"
                            );
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 1
                    color: themeManager.borderPrimary
                }

                // Token Input Section
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    RowLayout {
                        Layout.fillWidth: true
                        Text {
                            text: "PERSONAL ACCESS TOKEN (CLASSIC OR FINE-GRAINED)"
                            color: themeManager.textMuted
                            font.pixelSize: 11
                            font.weight: Font.Bold
                            Layout.fillWidth: true
                        }

                        ActionButton {
                            text: "Generate Token on GitHub (All Scopes Pre-selected)"
                            iconName: "external"
                            btnStyle: "subtle"
                            small: true
                            onClicked: backendBridge.openUrl("https://github.com/settings/tokens/new?description=DevSyncStudio_FullAccess&scopes=repo,workflow,write:packages,read:packages,delete:packages,admin:org,admin:public_key,admin:repo_hook,admin:org_hook,gist,notifications,user,delete_repo,write:discussion,admin:enterprise,audit_log,codespace,project,admin:gpg_key")
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10

                        Rectangle {
                            Layout.fillWidth: true
                            height: 38
                            radius: 6
                            color: themeManager.bgInput
                            border.color: tokenField.activeFocus ? themeManager.accent : themeManager.borderPrimary
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 8

                                TextField {
                                    id: tokenField
                                    Layout.fillWidth: true
                                    color: themeManager.textPrimary
                                    font.pixelSize: 13
                                    echoMode: root.showToken ? TextInput.Normal : TextInput.Password
                                    placeholderText: "ghp_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
                                    background: null
                                }

                                Text {
                                    text: root.showToken ? "Hide" : "Show"
                                    color: themeManager.textMuted
                                    font.pixelSize: 11
                                    font.weight: Font.Medium

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.showToken = !root.showToken
                                    }
                                }
                            }
                        }

                        ActionButton {
                            text: "Save Token"
                            iconName: "shield"
                            btnStyle: "primary"
                            onClicked: {
                                var val = tokenField.text.trim();
                                if (!val) {
                                    toast.show("Please enter a GitHub personal access token.", "warning");
                                    return;
                                }
                                backendBridge.sendRequest("github.set_token", {"token": val}, function(success) {
                                    if (success) {
                                        toast.show("Token securely stored in OS Keyring.", "success");
                                        tokenField.text = "";
                                        root.checkConnection();
                                    }
                                });
                            }
                        }

                        ActionButton {
                            text: "Test Connection"
                            iconName: "refresh"
                            btnStyle: "secondary"
                            busy: root.isTesting
                            onClicked: root.checkConnection()
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 10
                        Rectangle {
                            height: 22
                            width: encLabel.implicitWidth + 24
                            radius: 4
                            color: Qt.rgba(themeManager.success.r, themeManager.success.g, themeManager.success.b, 0.15)
                            border.color: themeManager.success
                            border.width: 1
                            Row {
                                anchors.centerIn: parent
                                spacing: 6
                                AppIcon {
                                    name: "shield"
                                    size: 11
                                    color: themeManager.success
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                                Text {
                                    id: encLabel
                                    text: "End-to-End Encrypted (Windows DPAPI + AES-256-GCM)"
                                    color: themeManager.success
                                    font.pixelSize: 10
                                    font.weight: Font.DemiBold
                                    anchors.verticalCenter: parent.verticalCenter
                                }
                            }
                        }
                        Item { Layout.fillWidth: true }
                        Text {
                            text: "All required repository & organization scopes will be pre-configured."
                            color: themeManager.accent
                            font.pixelSize: 11
                        }
                    }
                }
            }
        }

        // Remote Repositories Section
        ColumnLayout {
            visible: root.isConnected && root.remoteRepos.length > 0
            Layout.fillWidth: true
            spacing: 12

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Text {
                    text: "YOUR GITHUB REPOSITORIES (" + root.remoteRepos.length + ")"
                    color: themeManager.textMuted
                    font.pixelSize: 11
                    font.weight: Font.Bold
                }

                Item { Layout.fillWidth: true }

                ActionButton {
                    text: "Create New GitHub Repo"
                    iconName: "plus"
                    btnStyle: "primary"
                    small: true
                    onClicked: {
                        appWindow.openCreateRepoDialog();
                    }
                }
            }

            Repeater {
                model: root.remoteRepos

                Rectangle {
                    Layout.fillWidth: true
                    height: 52
                    radius: 6
                    color: themeManager.bgCard
                    border.color: themeManager.borderPrimary
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 16
                        anchors.rightMargin: 16
                        spacing: 12

                        AppIcon {
                            name: modelData.private ? "shield" : "repo"
                            size: 15
                            color: themeManager.accent
                        }

                        Column {
                            spacing: 2
                            Text {
                                text: modelData.full_name
                                color: themeManager.textPrimary
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: modelData.description || "No description"
                                color: themeManager.textMuted
                                font.pixelSize: 11
                                elide: Text.ElideRight
                            }
                        }

                        Item { Layout.fillWidth: true }

                        ActionButton {
                            text: "Clone to Local"
                            iconName: "pull"
                            btnStyle: "primary"
                            small: true
                            onClicked: {
                                var target = "D:/DevSyncProjects/" + modelData.name;
                                toast.show("Cloning " + modelData.name + "...", "info");
                                backendBridge.sendRequest("git.clone", {"url": modelData.clone_url, "target_dir": target, "name": modelData.name}, function(success, data, err) {
                                    if (success) {
                                        toast.show("Cloned " + modelData.name + " successfully!", "success");
                                        root.checkConnection();
                                    } else {
                                        toast.show("Clone failed: " + err, "error");
                                    }
                                });
                            }
                        }

                        ActionButton {
                            text: "Open"
                            iconName: "external"
                            btnStyle: "subtle"
                            small: true
                            onClicked: backendBridge.openUrl(modelData.html_url)
                        }
                    }
                }
            }
        }
    }
}
