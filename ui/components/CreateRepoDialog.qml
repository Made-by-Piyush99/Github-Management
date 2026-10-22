import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property string ownerName: ""
    property bool isPrivate: true
    property bool busy: false
    property string errorMessage: ""

    signal repositoryCreated(var repoData)
    signal cancelled()

    visible: false
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.7)
    z: 9999

    function open(owner) {
        ownerName = owner || "User";
        nameField.text = "";
        descField.text = "";
        isPrivate = true;
        readmeCheck.checked = true;
        gitignoreCombo.currentIndex = 0;
        licenseCombo.currentIndex = 1; // Default to MIT
        errorMessage = "";
        busy = false;
        visible = true;
        nameField.forceActiveFocus();
    }

    function close() {
        visible = false;
        errorMessage = "";
        busy = false;
    }

    MouseArea {
        anchors.fill: parent
        onClicked: { /* Prevent clicking through */ }
    }

    Rectangle {
        width: 540
        implicitHeight: contentCol.implicitHeight + 40
        radius: 10
        anchors.centerIn: parent
        color: themeManager.bgCard
        border.color: themeManager.borderPrimary
        border.width: 1

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 24
            spacing: 14

            // Dialog Header
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text { text: "📦"; font.pixelSize: 22 }

                Column {
                    spacing: 2
                    Text {
                        text: "Create a new repository"
                        color: themeManager.textPrimary
                        font.pixelSize: 17
                        font.weight: Font.Bold
                    }
                    Text {
                        text: "A repository contains all project files, including the revision history."
                        color: themeManager.textSecondary
                        font.pixelSize: 11
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "✕"
                    color: themeManager.textMuted
                    font.pixelSize: 14
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: root.close()
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: themeManager.borderPrimary
            }

            // Repository Name
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "Repository name *"
                    color: themeManager.textPrimary
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Rectangle {
                        height: 36
                        width: ownerLabel.implicitWidth + 16
                        radius: 6
                        color: themeManager.bgPrimary
                        border.color: themeManager.borderPrimary
                        border.width: 1

                        Text {
                            id: ownerLabel
                            anchors.centerIn: parent
                            text: (root.ownerName || "owner") + " /"
                            color: themeManager.textSecondary
                            font.pixelSize: 12
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 36
                        radius: 6
                        color: themeManager.bgInput
                        border.color: nameField.activeFocus ? themeManager.accent : themeManager.borderPrimary
                        border.width: 1

                        TextField {
                            id: nameField
                            anchors.fill: parent
                            anchors.margins: 8
                            color: themeManager.textPrimary
                            font.pixelSize: 13
                            placeholderText: "e.g. awesome-project"
                            background: null
                        }
                    }
                }
            }

            // Description
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: "Description (optional)"
                    color: themeManager.textPrimary
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                Rectangle {
                    Layout.fillWidth: true
                    height: 36
                    radius: 6
                    color: themeManager.bgInput
                    border.color: descField.activeFocus ? themeManager.accent : themeManager.borderPrimary
                    border.width: 1

                    TextField {
                        id: descField
                        anchors.fill: parent
                        anchors.margins: 8
                        color: themeManager.textPrimary
                        font.pixelSize: 12
                        placeholderText: "Short description of what this project does..."
                        background: null
                    }
                }
            }

            // Visibility (Public vs Private)
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "Visibility"
                    color: themeManager.textPrimary
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    Rectangle {
                        Layout.fillWidth: true
                        height: 48
                        radius: 6
                        color: !root.isPrivate ? themeManager.accentMuted : themeManager.bgPrimary
                        border.color: !root.isPrivate ? themeManager.accent : themeManager.borderPrimary
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            RadioButton {
                                checked: !root.isPrivate
                                onToggled: root.isPrivate = false
                            }

                            Column {
                                Text { text: "Public 🌐"; color: themeManager.textPrimary; font.pixelSize: 12; font.weight: Font.Bold }
                                Text { text: "Anyone on the internet can see this repository."; color: themeManager.textMuted; font.pixelSize: 10 }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.isPrivate = false
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 48
                        radius: 6
                        color: root.isPrivate ? themeManager.accentMuted : themeManager.bgPrimary
                        border.color: root.isPrivate ? themeManager.accent : themeManager.borderPrimary
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 8

                            RadioButton {
                                checked: root.isPrivate
                                onToggled: root.isPrivate = true
                            }

                            Column {
                                Text { text: "Private 🔒"; color: themeManager.textPrimary; font.pixelSize: 12; font.weight: Font.Bold }
                                Text { text: "You choose who can see and commit."; color: themeManager.textMuted; font.pixelSize: 10 }
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: root.isPrivate = true
                        }
                    }
                }
            }

            // Initialize this repository with
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 6

                Text {
                    text: "Initialize this repository with:"
                    color: themeManager.textPrimary
                    font.pixelSize: 12
                    font.weight: Font.DemiBold
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    CheckBox {
                        id: readmeCheck
                        checked: true
                    }

                    Column {
                        Text { text: "Add a README file (README.md)"; color: themeManager.textPrimary; font.pixelSize: 12 }
                        Text { text: "This is where you can write a long description for your project."; color: themeManager.textMuted; font.pixelSize: 10 }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Column {
                        Layout.fillWidth: true
                        spacing: 2
                        Text { text: "Add .gitignore template:"; color: themeManager.textPrimary; font.pixelSize: 11 }
                        ComboBox {
                            id: gitignoreCombo
                            Layout.fillWidth: true
                            model: ["None", "Python", "Node", "C++", "Java", "Go", "Unity", "Rust"]
                        }
                    }

                    Column {
                        Layout.fillWidth: true
                        spacing: 2
                        Text { text: "Choose a license:"; color: themeManager.textPrimary; font.pixelSize: 11 }
                        ComboBox {
                            id: licenseCombo
                            Layout.fillWidth: true
                            model: [
                                "None",
                                "MIT License",
                                "Apache License 2.0",
                                "GNU General Public License v3.0",
                                "BSD 3-Clause",
                                "ISC License"
                            ]
                        }
                    }
                }
            }

            // Error display
            Text {
                visible: root.errorMessage !== ""
                text: root.errorMessage
                color: themeManager.danger
                font.pixelSize: 12
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: themeManager.borderPrimary
            }

            // Footer Buttons
            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Item { Layout.fillWidth: true }

                ActionButton {
                    text: "Cancel"
                    btnStyle: "subtle"
                    onClicked: root.close()
                }

                ActionButton {
                    text: "Create Repository"
                    iconText: "🚀"
                    btnStyle: "primary"
                    busy: root.busy
                    onClicked: {
                        var rName = nameField.text.trim();
                        if (!rName) {
                            root.errorMessage = "Please enter a repository name.";
                            return;
                        }

                        // Map license template name to identifier
                        var licMap = {
                            "None": "none",
                            "MIT License": "mit",
                            "Apache License 2.0": "apache-2.0",
                            "GNU General Public License v3.0": "gpl-3.0",
                            "BSD 3-Clause": "bsd-3-clause",
                            "ISC License": "isc"
                        };
                        var chosenLic = licMap[licenseCombo.currentText] || "none";
                        var chosenIgnore = gitignoreCombo.currentText;

                        root.busy = true;
                        root.errorMessage = "";

                        var payload = {
                            "name": rName,
                            "description": descField.text.trim(),
                            "private": root.isPrivate,
                            "auto_init": readmeCheck.checked,
                            "gitignore_template": chosenIgnore !== "None" ? chosenIgnore : null,
                            "license_template": chosenLic !== "none" ? chosenLic : null
                        };

                        backendBridge.sendRequest("github.create_repo", payload, function(success, data, err) {
                            root.busy = false;
                            if (success && data && data.repository) {
                                root.close();
                                root.repositoryCreated(data.repository);
                            } else {
                                root.errorMessage = err || "Failed to create repository on GitHub.";
                            }
                        });
                    }
                }
            }
        }
    }
}
