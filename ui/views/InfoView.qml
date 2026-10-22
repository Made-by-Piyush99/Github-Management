import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../components"

ScrollView {
    id: root

    signal requestAppTour()
    signal navigateToTab(int tabIndex)

    contentWidth: availableWidth
    clip: true

    ColumnLayout {
        width: parent.width
        anchors.margins: 24
        spacing: 24

        // Header Card with Tour Re-trigger
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: headerCol.implicitHeight + 36
            radius: 8
            gradient: Gradient {
                GradientStop { position: 0.0; color: themeManager.isDark ? "#162032" : "#EFF6FF" }
                GradientStop { position: 1.0; color: themeManager.bgCard }
            }
            border.color: themeManager.accent
            border.width: 1

            ColumnLayout {
                id: headerCol
                anchors.fill: parent
                anchors.margins: 20
                spacing: 12

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Text { text: "📖"; font.pixelSize: 28 }

                    Column {
                        spacing: 2
                        Text {
                            text: "DevSync Studio Knowledge Base & Interactive Guides"
                            color: themeManager.textPrimary
                            font.pixelSize: 18
                            font.weight: Font.Bold
                        }
                        Text {
                            text: "Everything you need to know about setting up Classic Tokens, creating repositories, and managing workflows."
                            color: themeManager.textSecondary
                            font.pixelSize: 12
                        }
                    }

                    Item { Layout.fillWidth: true }

                    ActionButton {
                        text: "🎬 Start App Tour"
                        btnStyle: "primary"
                        onClicked: root.requestAppTour()
                    }
                }
            }
        }

        // Section 1: How to Generate & Connect a Classic Token
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: tokenGuideCol.implicitHeight + 36
            radius: 8
            color: themeManager.bgCard
            border.color: themeManager.borderPrimary
            border.width: 1

            ColumnLayout {
                id: tokenGuideCol
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text { text: "🔑"; font.pixelSize: 18 }
                    Text {
                        text: "How to Generate & Connect a GitHub Classic Token"
                        color: themeManager.textPrimary
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }
                    Item { Layout.fillWidth: true }

                    ActionButton {
                        text: "🌐 Generate Token on GitHub (Pre-configured)"
                        iconText: "↗️"
                        btnStyle: "primary"
                        small: true
                        onClicked: backendBridge.openUrl("https://github.com/settings/tokens/new?scopes=repo,read:user&description=DevSyncStudio")
                    }
                }

                Text {
                    text: "DevSync Studio uses a Personal Access Token (Classic) to authenticate with GitHub. Tokens are stored encrypted in your Windows Credential Manager and never saved in plaintext."
                    color: themeManager.textSecondary
                    font.pixelSize: 12
                    lineHeight: 1.3
                }

                // Step by step list
                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Repeater {
                        model: [
                            {
                                "step": "1",
                                "title": "Open GitHub Token Generator",
                                "desc": "Click the 'Generate Token on GitHub' button above. It opens GitHub's token generator with the required scopes pre-filled."
                            },
                            {
                                "step": "2",
                                "title": "Confirm Scopes (Permissions)",
                                "desc": "Ensure that 'repo' (Full control of private repositories) and 'read:user' (Read profile data) are checked."
                            },
                            {
                                "step": "3",
                                "title": "Set Expiration & Generate",
                                "desc": "Set an expiration date (e.g. 90 days or No expiration), scroll down, and click the green 'Generate token' button."
                            },
                            {
                                "step": "4",
                                "title": "Copy the Token",
                                "desc": "Copy the generated token string starting with 'ghp_...'. (Note: GitHub only shows this once)."
                            },
                            {
                                "step": "5",
                                "title": "Paste into DevSync Studio",
                                "desc": "Go to the GitHub tab or Settings, paste your token into the Personal Access Token field, and click 'Save Token'."
                            }
                        ]

                        Rectangle {
                            Layout.fillWidth: true
                            height: 48
                            radius: 6
                            color: themeManager.bgPrimary
                            border.color: themeManager.borderPrimary
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.leftMargin: 12
                                anchors.rightMargin: 12
                                spacing: 12

                                Rectangle {
                                    width: 24
                                    height: 24
                                    radius: 12
                                    color: themeManager.accent
                                    Text {
                                        anchors.centerIn: parent
                                        text: modelData.step
                                        color: "#FFFFFF"
                                        font.pixelSize: 11
                                        font.weight: Font.Bold
                                    }
                                }

                                Text {
                                    text: modelData.title
                                    color: themeManager.textPrimary
                                    font.pixelSize: 12
                                    font.weight: Font.DemiBold
                                }

                                Text {
                                    text: "— " + modelData.desc
                                    color: themeManager.textMuted
                                    font.pixelSize: 11
                                    elide: Text.ElideRight
                                    Layout.fillWidth: true
                                }
                            }
                        }
                    }
                }
            }
        }

        // Section 2: How to Create a New Repository (with README, gitignore, and License)
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: repoGuideCol.implicitHeight + 36
            radius: 8
            color: themeManager.bgCard
            border.color: themeManager.borderPrimary
            border.width: 1

            ColumnLayout {
                id: repoGuideCol
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text { text: "🚀"; font.pixelSize: 18 }
                    Text {
                        text: "How to Create a Repository with Description, README & License"
                        color: themeManager.textPrimary
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }
                    Item { Layout.fillWidth: true }

                    ActionButton {
                        text: "Go to GitHub Tab"
                        iconText: "🐙"
                        btnStyle: "secondary"
                        small: true
                        onClicked: root.navigateToTab(6)
                    }
                }

                Text {
                    text: "You can create brand new repositories directly on GitHub without opening a browser, matching GitHub's full creation flow:"
                    color: themeManager.textSecondary
                    font.pixelSize: 12
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: 2
                    rowSpacing: 10
                    columnSpacing: 16

                    Rectangle {
                        Layout.fillWidth: true
                        height: 70
                        radius: 6
                        color: themeManager.bgPrimary
                        border.color: themeManager.borderPrimary
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4
                            Text { text: "1. Repository Name & Description"; color: themeManager.textPrimary; font.pixelSize: 12; font.weight: Font.Bold }
                            Text { text: "Enter a unique repository name and optional project description."; color: themeManager.textMuted; font.pixelSize: 11 }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 70
                        radius: 6
                        color: themeManager.bgPrimary
                        border.color: themeManager.borderPrimary
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4
                            Text { text: "2. Public or Private Visibility"; color: themeManager.textPrimary; font.pixelSize: 12; font.weight: Font.Bold }
                            Text { text: "Choose Public to share with the world or Private for private access."; color: themeManager.textMuted; font.pixelSize: 11 }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 70
                        radius: 6
                        color: themeManager.bgPrimary
                        border.color: themeManager.borderPrimary
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4
                            Text { text: "3. README.md & .gitignore"; color: themeManager.textPrimary; font.pixelSize: 12; font.weight: Font.Bold }
                            Text { text: "Automatically generate a README.md and a language template (Python, Node, C++, Java, etc.)."; color: themeManager.textMuted; font.pixelSize: 11 }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 70
                        radius: 6
                        color: themeManager.bgPrimary
                        border.color: themeManager.borderPrimary
                        border.width: 1

                        Column {
                            anchors.fill: parent
                            anchors.margins: 10
                            spacing: 4
                            Text { text: "4. Open-Source License"; color: themeManager.textPrimary; font.pixelSize: 12; font.weight: Font.Bold }
                            Text { text: "Choose from standard licenses (MIT, Apache 2.0, GNU GPLv3, BSD 3-Clause, ISC)."; color: themeManager.textMuted; font.pixelSize: 11 }
                        }
                    }
                }
            }
        }

        // Section 3: Understanding the Application Tabs
        Rectangle {
            Layout.fillWidth: true
            implicitHeight: appTabsCol.implicitHeight + 36
            radius: 8
            color: themeManager.bgCard
            border.color: themeManager.borderPrimary
            border.width: 1

            ColumnLayout {
                id: appTabsCol
                anchors.fill: parent
                anchors.margins: 20
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10
                    Text { text: "⚡"; font.pixelSize: 18 }
                    Text {
                        text: "Understanding the Application Tabs & Workflows"
                        color: themeManager.textPrimary
                        font.pixelSize: 15
                        font.weight: Font.Bold
                    }
                }

                Repeater {
                    model: [
                        {
                            "name": "Dashboard",
                            "icon": "📊",
                            "desc": "Main overview showing total projects, Git repos, GitHub repos, uncommitted files, pending pushes, pending pulls, and real-time synchronization health. Clicking any project card opens its complete health report."
                        },
                        {
                            "name": "Projects",
                            "icon": "📁",
                            "desc": "Manage registered folders. Add existing local project directories, detect Git status, initialize Git with one click, pin favorite projects, and safely remove projects without touching local files."
                        },
                        {
                            "name": "Repositories",
                            "icon": "📦",
                            "desc": "Central repository hub. Displays both local repositories and remote GitHub repositories. Uncloned repos feature a 1-click 'Clone to Local' button. Cloned repos offer Fetch, Pull, and Push."
                        },
                        {
                            "name": "Branches",
                            "icon": "🌿",
                            "desc": "Local and remote branch management. Create feature branches, switch between branches, inspect upstream tracking, and safely delete branches with active branch protection."
                        },
                        {
                            "name": "Changes & Commits",
                            "icon": "📝",
                            "desc": "Inspect working-tree modifications line by line with green (+) additions and red (-) deletions. Stage/unstage individual files or all, discard unwanted edits with confirmation, and commit/push."
                        },
                        {
                            "name": "Activity & Reports",
                            "icon": "📜",
                            "desc": "Complete audit trail tracking all Git and sync operations with timestamps, durations, and error diagnostics. Filter by status (Success/Failed) and export logs to CSV or JSON."
                        },
                        {
                            "name": "GitHub",
                            "icon": "🐙",
                            "desc": "GitHub integration hub. Connect Personal Access Tokens, test connections, view API rate limits, browse your remote repositories, and create brand new repositories with README, .gitignore, and licenses."
                        },
                        {
                            "name": "Settings",
                            "icon": "⚙️",
                            "desc": "Preferences and diagnostics. Toggle Dark/Light theme, configure custom Git executable paths, set GitHub API endpoints (GitHub Enterprise support), and adjust auto-refresh intervals."
                        }
                    ]

                    Rectangle {
                        Layout.fillWidth: true
                        height: 52
                        radius: 6
                        color: themeManager.bgPrimary
                        border.color: themeManager.borderPrimary
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 12

                            Text { text: modelData.icon; font.pixelSize: 16 }

                            Text {
                                text: modelData.name
                                color: themeManager.accent
                                font.pixelSize: 13
                                font.weight: Font.Bold
                                Layout.preferredWidth: 140
                            }

                            Text {
                                text: modelData.desc
                                color: themeManager.textSecondary
                                font.pixelSize: 11
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                    }
                }
            }
        }
    }
}
