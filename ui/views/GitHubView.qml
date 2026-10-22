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

                        Text {
                            anchors.centerIn: parent
                            text: "🐙"
                            font.pixelSize: 22
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
                        iconText: "🔌"
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

                    Text {
                        text: "PERSONAL ACCESS TOKEN (CLASSIC OR FINE-GRAINED)"
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
                                    text: root.showToken ? "🙈" : "👁️"
                                    font.pixelSize: 14

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
                            iconText: "💾"
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
                            iconText: "⚡"
                            btnStyle: "secondary"
                            busy: root.isTesting
                            onClicked: root.checkConnection()
                        }
                    }

                    Text {
                        text: "🔒 Required permissions: 'repo' (Full control of private repositories) and 'read:user'."
                        color: themeManager.textMuted
                        font.pixelSize: 11
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
                    iconText: "➕"
                    btnStyle: "primary"
                    small: true
                    onClicked: {
                        textInputDialog.open(
                            "Create GitHub Repository",
                            "Enter the name of the new remote repository to create on GitHub:",
                            "my-new-repo",
                            "",
                            function(repoName) {
                                backendBridge.sendRequest(
                                    "github.create_repo",
                                    {"name": repoName, "description": "", "private": true, "auto_init": false},
                                    function(success, data, err) {
                                        if (success) {
                                            toast.show("Created GitHub repository: " + data.repository.full_name, "success");
                                            root.loadRemoteRepos();
                                        } else {
                                            toast.show("Failed: " + err, "error");
                                        }
                                    }
                                );
                            }
                        );
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

                        Text {
                            text: modelData.private ? "🔒" : "🌐"
                            font.pixelSize: 14
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

                        Text {
                            text: "⭐ " + modelData.stargazers_count
                            color: themeManager.textSecondary
                            font.pixelSize: 11
                        }

                        ActionButton {
                            text: "Open"
                            iconText: "↗️"
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
