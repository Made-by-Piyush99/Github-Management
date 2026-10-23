import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property var project: null
    property string uploadMode: "new" // "new" or "existing"
    property bool isPrivate: true
    property bool createGitignore: true
    property bool busy: false
    property string statusMessage: ""
    property string errorMessage: ""
    property bool isSuccess: false
    property var uploadResult: null
    property var githubRepos: []
    property var filteredRepos: []
    property var selectedRepo: null
    property string repoSearchQuery: ""

    signal uploadCompleted(var proj, var res)
    signal closed()

    visible: false
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.78)
    z: 9999

    function open(proj) {
        if (!proj) return;
        project = proj;
        uploadMode = "new";
        isPrivate = true;
        createGitignore = true;
        busy = false;
        statusMessage = "";
        errorMessage = "";
        isSuccess = false;
        uploadResult = null;
        selectedRepo = null;
        repoSearchQuery = "";

        var safeName = (proj.name || "project").replace(/\s+/g, "-");
        nameField.text = safeName;
        descField.text = "";
        branchField.text = proj.current_branch || proj.default_branch || "main";
        commitMsgField.text = "Initial commit: upload " + (proj.name || "project") + " structure";

        visible = true;
        loadGitHubRepositories();
    }

    function close() {
        if (busy) return;
        visible = false;
        root.closed();
    }

    function loadGitHubRepositories() {
        backendBridge.sendRequest("github.list_repos", {"per_page": 100}, function(success, data, error) {
            if (success && data && data.repositories) {
                root.githubRepos = data.repositories;
                filterRepos();
            } else {
                root.githubRepos = [];
                root.filteredRepos = [];
            }
        });
    }

    function filterRepos() {
        if (!root.repoSearchQuery) {
            root.filteredRepos = root.githubRepos;
            return;
        }
        var q = root.repoSearchQuery.toLowerCase();
        var list = [];
        for (var i = 0; i < root.githubRepos.length; i++) {
            var r = root.githubRepos[i];
            if ((r.name && r.name.toLowerCase().indexOf(q) !== -1) ||
                (r.full_name && r.full_name.toLowerCase().indexOf(q) !== -1) ||
                (r.description && r.description.toLowerCase().indexOf(q) !== -1)) {
                list.push(r);
            }
        }
        root.filteredRepos = list;
    }

    function startUpload() {
        if (!project) return;
        errorMessage = "";

        var branch = branchField.text.trim() || "main";
        var commitMsg = commitMsgField.text.trim() || "Initial commit: upload project structure";

        var payload = {
            "project_id": project.id,
            "mode": root.uploadMode,
            "branch": branch,
            "commit_message": commitMsg,
            "create_gitignore": root.createGitignore
        };

        if (root.uploadMode === "new") {
            var rName = nameField.text.trim();
            if (!rName) {
                errorMessage = "Please enter a repository name.";
                return;
            }
            payload.repo_name = rName;
            payload.description = descField.text.trim();
            payload.private = root.isPrivate;
        } else {
            if (!root.selectedRepo) {
                errorMessage = "Please select an existing GitHub repository from the list.";
                return;
            }
            payload.remote_url = root.selectedRepo.clone_url;
            payload.repo_name = root.selectedRepo.name;
        }

        busy = true;
        statusMessage = "Configuring project structure and initializing Git...";

        backendBridge.sendRequest("projects.upload_to_github", payload, function(success, data, err) {
            busy = false;
            if (success) {
                root.isSuccess = true;
                root.uploadResult = data;
                toast.show("Full project uploaded to GitHub successfully!", "success");
                root.uploadCompleted(project, data);
            } else {
                root.errorMessage = err || "Failed to upload project. Please check GitHub connection and try again.";
                toast.show("Upload failed: " + err, "error");
            }
        });
    }

    MouseArea {
        anchors.fill: parent
        onClicked: { /* Prevent dismiss on outside click */ }
    }

    // Modal Card
    Rectangle {
        width: 620
        height: Math.min(parent.height - 40, 680)
        radius: 12
        anchors.centerIn: parent
        color: themeManager.isDark ? "#0E1422" : themeManager.bgCard
        border.color: themeManager.isDark ? Qt.rgba(56/255, 189/255, 248/255, 0.25) : themeManager.borderPrimary
        border.width: 1

        // Top edge subtle glow
        Rectangle {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.top: parent.top
            anchors.margins: 1
            height: 1
            radius: 12
            color: Qt.rgba(56/255, 189/255, 248/255, 0.4)
            visible: themeManager.isDark
        }

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            // Header Row
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Rectangle {
                    width: 38
                    height: 38
                    radius: 8
                    color: Qt.rgba(56/255, 189/255, 248/255, 0.12)
                    border.color: themeManager.accent
                    border.width: 1

                    AppIcon {
                        anchors.centerIn: parent
                        name: "push"
                        size: 20
                        color: themeManager.accent
                    }
                }

                Column {
                    Layout.fillWidth: true
                    spacing: 2

                    Text {
                        text: root.isSuccess ? "Project Successfully Uploaded!" : "Upload Project to GitHub"
                        color: themeManager.textPrimary
                        font.pixelSize: 17
                        font.weight: Font.Bold
                    }

                    Text {
                        text: root.isSuccess ? "Repository is linked and live on GitHub with upstream tracking." : "Upload full project files with proper structure, initialize Git, and track remote."
                        color: themeManager.textSecondary
                        font.pixelSize: 12
                    }
                }

                ActionButton {
                    text: ""
                    iconName: "plus"
                    rotation: 45
                    btnStyle: "subtle"
                    enabled: !root.busy
                    onClicked: root.close()
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: themeManager.borderPrimary
            }

            // ==========================================
            // Main Content Area: Configuration vs Success
            // ==========================================
            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.isSuccess ? 1 : 0

                // ----------------------------------------
                // Screen 0: Configuration & Upload Options
                // ----------------------------------------
                ScrollView {
                    clip: true
                    contentWidth: availableWidth

                    ColumnLayout {
                        width: parent.width
                        spacing: 14

                        // Project Overview Pill Card
                        Rectangle {
                            Layout.fillWidth: true
                            height: 52
                            radius: 8
                            color: themeManager.isDark ? Qt.rgba(255, 255, 255, 0.03) : Qt.rgba(0, 0, 0, 0.03)
                            border.color: themeManager.borderPrimary
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10

                                AppIcon { name: "folder"; size: 16; color: themeManager.accent }

                                Column {
                                    Layout.fillWidth: true
                                    spacing: 1
                                    Text {
                                        text: root.project ? (root.project.name || "Local Project") : ""
                                        color: themeManager.textPrimary
                                        font.pixelSize: 13
                                        font.weight: Font.Bold
                                    }
                                    Text {
                                        text: root.project ? (root.project.local_path || "") : ""
                                        color: themeManager.textMuted
                                        font.pixelSize: 10
                                        elide: Text.ElideMiddle
                                    }
                                }

                                Rectangle {
                                    height: 22
                                    width: branchBadgeText.implicitWidth + 12
                                    radius: 11
                                    color: Qt.rgba(56/255, 189/255, 248/255, 0.15)
                                    border.color: themeManager.accent
                                    border.width: 1

                                    Text {
                                        id: branchBadgeText
                                        anchors.centerIn: parent
                                        text: root.project ? ((root.project.current_branch || root.project.default_branch || "main")) : "main"
                                        color: themeManager.accent
                                        font.pixelSize: 10
                                        font.weight: Font.DemiBold
                                    }
                                }
                            }
                        }

                        // Mode Selector Pills: Create New vs Select Existing
                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Rectangle {
                                Layout.fillWidth: true
                                height: 38
                                radius: 7
                                color: root.uploadMode === "new" ? (themeManager.isDark ? Qt.rgba(56/255, 189/255, 248/255, 0.16) : Qt.rgba(2, 132, 199, 0.12)) : (themeManager.isDark ? Qt.rgba(255, 255, 255, 0.03) : Qt.rgba(0, 0, 0, 0.03))
                                border.color: root.uploadMode === "new" ? themeManager.accent : themeManager.borderPrimary
                                border.width: 1

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.uploadMode = "new"
                                }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    AppIcon {
                                        name: "plus"
                                        size: 14
                                        color: root.uploadMode === "new" ? themeManager.accent : themeManager.textMuted
                                    }
                                    Text {
                                        text: "Create New Repository on GitHub"
                                        color: root.uploadMode === "new" ? themeManager.textPrimary : themeManager.textSecondary
                                        font.pixelSize: 12
                                        font.weight: root.uploadMode === "new" ? Font.DemiBold : Font.Normal
                                    }
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                height: 38
                                radius: 7
                                color: root.uploadMode === "existing" ? (themeManager.isDark ? Qt.rgba(56/255, 189/255, 248/255, 0.16) : Qt.rgba(2, 132, 199, 0.12)) : (themeManager.isDark ? Qt.rgba(255, 255, 255, 0.03) : Qt.rgba(0, 0, 0, 0.03))
                                border.color: root.uploadMode === "existing" ? themeManager.accent : themeManager.borderPrimary
                                border.width: 1

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: root.uploadMode = "existing"
                                }

                                RowLayout {
                                    anchors.centerIn: parent
                                    spacing: 8
                                    AppIcon {
                                        name: "repo"
                                        size: 14
                                        color: root.uploadMode === "existing" ? themeManager.accent : themeManager.textMuted
                                    }
                                    Text {
                                        text: "Select Existing GitHub Repository"
                                        color: root.uploadMode === "existing" ? themeManager.textPrimary : themeManager.textSecondary
                                        font.pixelSize: 12
                                        font.weight: root.uploadMode === "existing" ? Font.DemiBold : Font.Normal
                                    }
                                }
                            }
                        }

                        // Mode 1: New Repository Form
                        ColumnLayout {
                            visible: root.uploadMode === "new"
                            Layout.fillWidth: true
                            spacing: 10

                            // Name Field
                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    text: "Repository Name *"
                                    color: themeManager.textPrimary
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 36
                                    radius: 7
                                    color: themeManager.isDark ? Qt.rgba(255, 255, 255, 0.04) : themeManager.bgInput
                                    border.color: nameField.activeFocus ? themeManager.accent : themeManager.borderPrimary
                                    border.width: 1

                                    TextField {
                                        id: nameField
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        color: themeManager.textPrimary
                                        font.pixelSize: 12
                                        placeholderText: "e.g. awesome-project"
                                        background: null
                                    }
                                }
                            }

                            // Description Field
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
                                    radius: 7
                                    color: themeManager.isDark ? Qt.rgba(255, 255, 255, 0.04) : themeManager.bgInput
                                    border.color: descField.activeFocus ? themeManager.accent : themeManager.borderPrimary
                                    border.width: 1

                                    TextField {
                                        id: descField
                                        anchors.fill: parent
                                        anchors.margins: 8
                                        color: themeManager.textPrimary
                                        font.pixelSize: 12
                                        placeholderText: "Short summary of what this project contains..."
                                        background: null
                                    }
                                }
                            }

                            // Visibility Radios
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 12

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 44
                                    radius: 7
                                    color: !root.isPrivate ? (themeManager.isDark ? Qt.rgba(56/255, 189/255, 248/255, 0.12) : Qt.rgba(2, 132, 199, 0.1)) : (themeManager.isDark ? Qt.rgba(255, 255, 255, 0.03) : Qt.rgba(0, 0, 0, 0.03))
                                    border.color: !root.isPrivate ? themeManager.accent : themeManager.borderPrimary
                                    border.width: 1

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.isPrivate = false
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 8
                                        AppIcon { name: "repo"; size: 14; color: !root.isPrivate ? themeManager.accent : themeManager.textMuted }
                                        Column {
                                            spacing: 1
                                            Text { text: "Public"; color: themeManager.textPrimary; font.pixelSize: 12; font.weight: Font.DemiBold }
                                            Text { text: "Anyone can see this repository"; color: themeManager.textMuted; font.pixelSize: 10 }
                                        }
                                    }
                                }

                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 44
                                    radius: 7
                                    color: root.isPrivate ? (themeManager.isDark ? Qt.rgba(56/255, 189/255, 248/255, 0.12) : Qt.rgba(2, 132, 199, 0.1)) : (themeManager.isDark ? Qt.rgba(255, 255, 255, 0.03) : Qt.rgba(0, 0, 0, 0.03))
                                    border.color: root.isPrivate ? themeManager.accent : themeManager.borderPrimary
                                    border.width: 1

                                    MouseArea {
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.isPrivate = true
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.margins: 10
                                        spacing: 8
                                        AppIcon { name: "shield"; size: 14; color: root.isPrivate ? themeManager.accent : themeManager.textMuted }
                                        Column {
                                            spacing: 1
                                            Text { text: "Private (Recommended)"; color: themeManager.textPrimary; font.pixelSize: 12; font.weight: Font.DemiBold }
                                            Text { text: "Only you can access this repository"; color: themeManager.textMuted; font.pixelSize: 10 }
                                        }
                                    }
                                }
                            }
                        }

                        // Mode 2: Existing Repository Selector
                        ColumnLayout {
                            visible: root.uploadMode === "existing"
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: "Choose Remote Repository from your GitHub Account"
                                color: themeManager.textPrimary
                                font.pixelSize: 12
                                font.weight: Font.DemiBold
                            }

                            // Search filter box
                            Rectangle {
                                Layout.fillWidth: true
                                height: 32
                                radius: 6
                                color: themeManager.isDark ? Qt.rgba(255, 255, 255, 0.04) : themeManager.bgInput
                                border.color: themeManager.borderPrimary
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.margins: 6
                                    spacing: 6
                                    AppIcon { name: "search"; size: 12; color: themeManager.textMuted }
                                    TextInput {
                                        id: repoFilterInput
                                        Layout.fillWidth: true
                                        color: themeManager.textPrimary
                                        font.pixelSize: 11
                                        clip: true
                                        onTextChanged: {
                                            root.repoSearchQuery = text;
                                            root.filterRepos();
                                        }
                                        Text {
                                            anchors.fill: parent
                                            visible: !repoFilterInput.text
                                            text: "Search your GitHub repositories..."
                                            color: themeManager.textMuted
                                            font.pixelSize: 11
                                            verticalAlignment: Text.AlignVCenter
                                        }
                                    }
                                }
                            }

                            // Repo List View
                            Rectangle {
                                Layout.fillWidth: true
                                height: 130
                                radius: 7
                                color: themeManager.isDark ? Qt.rgba(255, 255, 255, 0.02) : Qt.rgba(0, 0, 0, 0.02)
                                border.color: themeManager.borderPrimary
                                border.width: 1
                                clip: true

                            ListView {
                                id: repoList
                                anchors.fill: parent
                                anchors.margins: 4
                                model: root.filteredRepos
                                boundsBehavior: Flickable.StopAtBounds
                                ScrollBar.vertical: ScrollBar { policy: ScrollBar.AsNeeded }

                                delegate: Rectangle {
                                    width: ListView.view.width
                                    height: 38
                                    radius: 5
                                    color: (root.selectedRepo && root.selectedRepo.id === modelData.id) ? (themeManager.isDark ? Qt.rgba(56/255, 189/255, 248/255, 0.18) : Qt.rgba(2, 132, 199, 0.12)) : (itemMouse.containsMouse ? (themeManager.isDark ? Qt.rgba(255, 255, 255, 0.04) : Qt.rgba(0, 0, 0, 0.04)) : "transparent")

                                    MouseArea {
                                        id: itemMouse
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: root.selectedRepo = modelData
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        AppIcon {
                                            name: modelData.private ? "shield" : "repo"
                                            size: 13
                                            color: (root.selectedRepo && root.selectedRepo.id === modelData.id) ? themeManager.accent : themeManager.textSecondary
                                        }

                                        Column {
                                            Layout.fillWidth: true
                                            spacing: 1
                                            Text {
                                                text: modelData.full_name || modelData.name
                                                color: themeManager.textPrimary
                                                font.pixelSize: 12
                                                font.weight: (root.selectedRepo && root.selectedRepo.id === modelData.id) ? Font.DemiBold : Font.Normal
                                            }
                                            Text {
                                                visible: !!modelData.description
                                                text: modelData.description
                                                color: themeManager.textMuted
                                                font.pixelSize: 10
                                                elide: Text.ElideRight
                                                width: parent.width
                                            }
                                        }

                                        Rectangle {
                                            height: 18
                                            width: privBadge.implicitWidth + 8
                                            radius: 3
                                            color: modelData.private ? Qt.rgba(234/255, 179/255, 8/255, 0.15) : Qt.rgba(34/255, 197/255, 94/255, 0.15)
                                            Text {
                                                id: privBadge
                                                anchors.centerIn: parent
                                                text: modelData.private ? "Private" : "Public"
                                                color: modelData.private ? themeManager.warning : themeManager.success
                                                font.pixelSize: 9
                                            }
                                        }
                                    }
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: root.filteredRepos.length === 0
                                    text: "No repositories found"
                                    color: themeManager.textMuted
                                    font.pixelSize: 11
                                }
                            }
                        }
                    }

                        // Proper Structure & Git Options Card
                        Rectangle {
                            Layout.fillWidth: true
                            implicitHeight: structCol.implicitHeight + 20
                            radius: 8
                            color: themeManager.isDark ? Qt.rgba(255, 255, 255, 0.025) : Qt.rgba(0, 0, 0, 0.02)
                            border.color: themeManager.borderPrimary
                            border.width: 1

                            ColumnLayout {
                                id: structCol
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    AppIcon { name: "check"; size: 14; color: themeManager.accent }

                                    Text {
                                        text: "Proper Structure & Git Rules"
                                        color: themeManager.textPrimary
                                        font.pixelSize: 12
                                        font.weight: Font.DemiBold
                                    }

                                    Item { Layout.fillWidth: true }
                                }

                                // Checkbox: .gitignore
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    CheckBox {
                                        id: gitignoreCheck
                                        checked: root.createGitignore
                                        onCheckedChanged: root.createGitignore = checked
                                    }

                                    Column {
                                        Layout.fillWidth: true
                                        spacing: 1
                                        Text {
                                            text: "Ensure clean structure with smart .gitignore"
                                            color: themeManager.textPrimary
                                            font.pixelSize: 11
                                            font.weight: Font.Medium
                                        }
                                        Text {
                                            text: "Automatically excludes node_modules, build artifacts, venv, .env, and temporary OS files"
                                            color: themeManager.textMuted
                                            font.pixelSize: 10
                                        }
                                    }
                                }

                                // Target Branch Field
                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 12

                                    Text {
                                        text: "Target Branch:"
                                        color: themeManager.textSecondary
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                    }

                                    Rectangle {
                                        width: 130
                                        height: 30
                                        radius: 6
                                        color: themeManager.isDark ? Qt.rgba(255, 255, 255, 0.04) : themeManager.bgInput
                                        border.color: themeManager.borderPrimary
                                        border.width: 1

                                        TextField {
                                            id: branchField
                                            anchors.fill: parent
                                            anchors.margins: 4
                                            color: themeManager.textPrimary
                                            font.pixelSize: 11
                                            background: null
                                        }
                                    }

                                    Item { Layout.fillWidth: true }
                                }

                                // Initial Commit Message Field
                                ColumnLayout {
                                    Layout.fillWidth: true
                                    spacing: 4

                                    Text {
                                        text: "Upload Commit Message:"
                                        color: themeManager.textSecondary
                                        font.pixelSize: 11
                                        font.weight: Font.Medium
                                    }

                                    Rectangle {
                                        Layout.fillWidth: true
                                        height: 32
                                        radius: 6
                                        color: themeManager.isDark ? Qt.rgba(255, 255, 255, 0.04) : themeManager.bgInput
                                        border.color: themeManager.borderPrimary
                                        border.width: 1

                                        TextField {
                                            id: commitMsgField
                                            anchors.fill: parent
                                            anchors.margins: 6
                                            color: themeManager.textPrimary
                                            font.pixelSize: 11
                                            background: null
                                        }
                                    }
                                }
                            }
                        }

                        // Error message
                        Text {
                            visible: root.errorMessage !== ""
                            Layout.fillWidth: true
                            text: root.errorMessage
                            color: themeManager.danger
                            font.pixelSize: 11
                            wrapMode: Text.Wrap
                        }
                    }
                }

                // ----------------------------------------
                // Screen 1: Success & Direct Remote Controls
                // ----------------------------------------
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    // Success Banner
                    Rectangle {
                        Layout.fillWidth: true
                        height: 90
                        radius: 10
                        color: Qt.rgba(34/255, 197/255, 94/255, 0.12)
                        border.color: themeManager.success
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 14

                            Rectangle {
                                width: 44
                                height: 44
                                radius: 22
                                color: Qt.rgba(34/255, 197/255, 94/255, 0.2)
                                AppIcon {
                                    anchors.centerIn: parent
                                    name: "check"
                                    size: 22
                                    color: themeManager.success
                                }
                            }

                            Column {
                                Layout.fillWidth: true
                                spacing: 2

                                Text {
                                    text: "Full Project Published to GitHub!"
                                    color: themeManager.success
                                    font.pixelSize: 15
                                    font.weight: Font.Bold
                                }

                                Text {
                                    text: "Your repository files are staged, committed, and pushed upstream with tracking."
                                    color: themeManager.textPrimary
                                    font.pixelSize: 12
                                }
                            }
                        }
                    }

                    // Remote Repository Link Card
                    Rectangle {
                        Layout.fillWidth: true
                        height: 64
                        radius: 8
                        color: themeManager.isDark ? Qt.rgba(255, 255, 255, 0.04) : Qt.rgba(0, 0, 0, 0.03)
                        border.color: themeManager.borderPrimary
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.margins: 14
                            spacing: 10

                            AppIcon { name: "github"; size: 18; color: themeManager.accent }

                            Column {
                                Layout.fillWidth: true
                                spacing: 2
                                Text {
                                    text: "GitHub Remote URL"
                                    color: themeManager.textMuted
                                    font.pixelSize: 10
                                    font.weight: Font.Bold
                                }
                                Text {
                                    text: root.uploadResult ? (root.uploadResult.remote_url || "") : ""
                                    color: themeManager.accent
                                    font.pixelSize: 12
                                    font.weight: Font.Medium
                                    elide: Text.ElideRight
                                }
                            }

                            ActionButton {
                                text: "Open on GitHub"
                                iconName: "external"
                                btnStyle: "secondary"
                                small: true
                                onClicked: {
                                    if (root.uploadResult && root.uploadResult.html_url) {
                                        Qt.openUrlExternally(root.uploadResult.html_url);
                                    }
                                }
                            }
                        }
                    }

                    // Direct Remote Management Panel: Pull, Push, & All Operations
                    Rectangle {
                        Layout.fillWidth: true
                        implicitHeight: opCol.implicitHeight + 24
                        radius: 8
                        color: themeManager.isDark ? Qt.rgba(255, 255, 255, 0.025) : Qt.rgba(0, 0, 0, 0.02)
                        border.color: themeManager.borderPrimary
                        border.width: 1

                        ColumnLayout {
                            id: opCol
                            anchors.fill: parent
                            anchors.margins: 16
                            spacing: 12

                            Text {
                                text: "REMOTE OPERATIONS (PULL, PUSH & SYNC)"
                                color: themeManager.textMuted
                                font.pixelSize: 11
                                font.weight: Font.Bold
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                ActionButton {
                                    Layout.fillWidth: true
                                    text: "Pull Changes"
                                    iconName: "pull"
                                    btnStyle: "secondary"
                                    onClicked: {
                                        toast.show("Pulling from origin...", "info");
                                        backendBridge.sendRequest("git.pull", {
                                            "path": root.project.local_path,
                                            "project_id": root.project.id
                                        }, function(s, d, err) {
                                            if (s) toast.show("Pull completed successfully!", "success");
                                            else toast.show("Pull failed: " + err, "error");
                                        });
                                    }
                                }

                                ActionButton {
                                    Layout.fillWidth: true
                                    text: "Push Changes"
                                    iconName: "push"
                                    btnStyle: "primary"
                                    onClicked: {
                                        toast.show("Pushing to origin...", "info");
                                        backendBridge.sendRequest("git.push", {
                                            "path": root.project.local_path,
                                            "project_id": root.project.id
                                        }, function(s, d, err) {
                                            if (s) toast.show("Push completed successfully!", "success");
                                            else toast.show("Push failed: " + err, "error");
                                        });
                                    }
                                }

                                ActionButton {
                                    Layout.fillWidth: true
                                    text: "Fetch Remote"
                                    iconName: "refresh"
                                    btnStyle: "subtle"
                                    onClicked: {
                                        toast.show("Fetching remote refs...", "info");
                                        backendBridge.sendRequest("git.fetch", {
                                            "path": root.project.local_path,
                                            "project_id": root.project.id
                                        }, function(s, d, err) {
                                            if (s) toast.show("Fetch completed!", "success");
                                            else toast.show("Fetch failed: " + err, "error");
                                        });
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10

                                ActionButton {
                                    Layout.fillWidth: true
                                    text: "Open Local Folder"
                                    iconName: "folder"
                                    btnStyle: "subtle"
                                    onClicked: backendBridge.openFolder(root.project.local_path)
                                }

                                ActionButton {
                                    Layout.fillWidth: true
                                    text: "Open in Changes Tab"
                                    iconName: "diff"
                                    btnStyle: "subtle"
                                    onClicked: {
                                        root.close();
                                        appWindow.activeTab = 4;
                                    }
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true }
                }
            }

            // Divider
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: themeManager.borderPrimary
            }

            // Bottom Action Bar
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Live status text during upload
                RowLayout {
                    visible: root.busy
                    spacing: 8
                    AppIcon {
                        name: "sync"
                        size: 14
                        color: themeManager.accent
                        NumberAnimation on rotation {
                            running: root.busy
                            from: 0; to: 360
                            duration: 1000
                            loops: Animation.Infinite
                        }
                    }
                    Text {
                        text: root.statusMessage || "Uploading project to GitHub..."
                        color: themeManager.accent
                        font.pixelSize: 11
                        font.weight: Font.Medium
                    }
                }

                Item { Layout.fillWidth: true }

                ActionButton {
                    text: root.isSuccess ? "Close" : "Cancel"
                    btnStyle: "subtle"
                    enabled: !root.busy
                    onClicked: root.close()
                }

                ActionButton {
                    visible: !root.isSuccess
                    text: "Upload Full Project to GitHub"
                    iconName: "push"
                    btnStyle: "primary"
                    busy: root.busy
                    onClicked: root.startUpload()
                }

                ActionButton {
                    visible: root.isSuccess
                    text: "Done"
                    btnStyle: "primary"
                    onClicked: {
                        root.close();
                        appWindow.refreshAll();
                    }
                }
            }
        }
    }
}
