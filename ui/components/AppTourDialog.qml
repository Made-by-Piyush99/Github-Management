import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property int currentStep: 0
    property bool visibleTour: false

    signal tourCompleted()
    signal tourSkipped()

    visible: visibleTour
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.75)
    z: 10000

    function open() {
        currentStep = 0;
        visibleTour = true;
    }

    function close() {
        visibleTour = false;
        backendBridge.sendRequest("settings.set", {"settings": {"tour_completed": true}});
    }

    MouseArea {
        anchors.fill: parent
        onClicked: { /* Prevent clicking through */ }
    }

    readonly property var slides: [
        {
            "icon": "⚡",
            "title": "Welcome to DevSync Studio",
            "subtitle": "Your Central Git & GitHub Desktop Command Center",
            "desc": "DevSync Studio gives you complete control over all your local repositories and GitHub projects from a single native desktop interface with real-time Git operations and analytics.",
            "bullet1": "🚀 1-Click clone from GitHub directly into your workspace",
            "bullet2": "📁 Full working-tree tracking, staging, diffs, and commits",
            "bullet3": "📊 Deep repository health reports & 14-day commit trends"
        },
        {
            "icon": "🔑",
            "title": "Connecting GitHub with a Classic Token",
            "subtitle": "Secure Personal Access Token via Windows Credential Vault",
            "desc": "Generate a Classic Personal Access Token on GitHub with 'repo' and 'read:user' permissions to securely authenticate.",
            "bullet1": "🔒 OS Credential Security: Tokens are never stored in plaintext in SQLite or logs",
            "bullet2": "🌐 Direct 1-click link to GitHub pre-configured token generator",
            "bullet3": "🐙 Instantly browses and syncs your remote repositories"
        },
        {
            "icon": "📦",
            "title": "Managing Projects & 1-Click Clone",
            "subtitle": "Add Local Folders or Clone Repositories",
            "desc": "Add any existing local directory on your drive, detect existing Git repositories, or initialize new ones. Remote GitHub repos can be cloned with a single click.",
            "bullet1": "📁 Native folder picker integration with automatic path validation",
            "bullet2": "📥 Clone directly to your chosen projects directory",
            "bullet3": "📌 Pin your most active projects to the top of your dashboard"
        },
        {
            "icon": "🌿",
            "title": "Branching, Diffs & Staging",
            "subtitle": "Full Git Workflow with Destructive Action Safeguards",
            "desc": "Inspect file modifications line-by-line with syntax-styled additions and deletions. Stage files, commit with messages, switch branches, and track remotes.",
            "bullet1": "📝 Unified diff viewer with line numbers and hunk breakdown",
            "bullet2": "🛡️ Active branch protection: Prevents deleting checked-out branches",
            "bullet3": "⚠️ Safe discard and conflict alerts: Never silently overwrites your work"
        },
        {
            "icon": "📊",
            "title": "Health Reports & Activity Audit Log",
            "subtitle": "Actionable Diagnostics & Real Performance Metrics",
            "desc": "Every project features an automated health report with a 0-100 score, 14-day activity trend charts, and tailored recommendations. Export reports and audit logs to CSV or JSON.",
            "bullet1": "📈 Real 14-day commit frequency chart and contributor metrics",
            "bullet2": "📜 Complete operation history tracking push, pull, fetch, and durations",
            "bullet3": "📑 Export reports to CSV and JSON for reporting and compliance"
        }
    ]

    Rectangle {
        width: 600
        implicitHeight: cardCol.implicitHeight + 48
        radius: 12
        anchors.centerIn: parent
        color: themeManager.bgCard
        border.color: themeManager.borderPrimary
        border.width: 1

        ColumnLayout {
            id: cardCol
            anchors.fill: parent
            anchors.margins: 28
            spacing: 18

            // Top Header: Step Indicator & Skip Button
            RowLayout {
                Layout.fillWidth: true

                // Step dots
                Row {
                    spacing: 6
                    Repeater {
                        model: 5
                        Rectangle {
                            width: index === root.currentStep ? 20 : 7
                            height: 7
                            radius: 3.5
                            color: index === root.currentStep ? themeManager.accent : themeManager.borderSecondary
                            Behavior on width { NumberAnimation { duration: 150 } }
                        }
                    }
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "Step " + (root.currentStep + 1) + " of 5"
                    color: themeManager.textMuted
                    font.pixelSize: 11
                }

                Item { Layout.preferredWidth: 10 }

                ActionButton {
                    text: "Skip Tour"
                    btnStyle: "subtle"
                    small: true
                    onClicked: {
                        root.close();
                        root.tourSkipped();
                    }
                }
            }

            // Big Icon Pill
            Rectangle {
                width: 60
                height: 60
                radius: 30
                color: themeManager.accentMuted
                border.color: themeManager.accent
                border.width: 1

                Text {
                    anchors.centerIn: parent
                    text: root.slides[root.currentStep].icon
                    font.pixelSize: 28
                }
            }

            // Title & Subtitle
            ColumnLayout {
                Layout.fillWidth: true
                spacing: 4

                Text {
                    text: root.slides[root.currentStep].title
                    color: themeManager.textPrimary
                    font.pixelSize: 20
                    font.weight: Font.Bold
                }

                Text {
                    text: root.slides[root.currentStep].subtitle
                    color: themeManager.accent
                    font.pixelSize: 13
                    font.weight: Font.Medium
                }
            }

            // Description
            Text {
                text: root.slides[root.currentStep].desc
                color: themeManager.textSecondary
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                lineHeight: 1.3
                Layout.fillWidth: true
            }

            // Bullet Highlights Card
            Rectangle {
                Layout.fillWidth: true
                implicitHeight: bulletCol.implicitHeight + 20
                radius: 8
                color: themeManager.bgPrimary
                border.color: themeManager.borderPrimary
                border.width: 1

                ColumnLayout {
                    id: bulletCol
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 8

                    Text {
                        text: root.slides[root.currentStep].bullet1
                        color: themeManager.textPrimary
                        font.pixelSize: 12
                    }
                    Text {
                        text: root.slides[root.currentStep].bullet2
                        color: themeManager.textPrimary
                        font.pixelSize: 12
                    }
                    Text {
                        text: root.slides[root.currentStep].bullet3
                        color: themeManager.textPrimary
                        font.pixelSize: 12
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: themeManager.borderPrimary
            }

            // Footer Navigation
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                ActionButton {
                    visible: root.currentStep > 0
                    text: "Previous"
                    btnStyle: "secondary"
                    onClicked: root.currentStep--
                }

                Item { Layout.fillWidth: true }

                ActionButton {
                    text: root.currentStep === 4 ? "Get Started 🚀" : "Next →"
                    btnStyle: "primary"
                    onClicked: {
                        if (root.currentStep < 4) {
                            root.currentStep++;
                        } else {
                            root.close();
                            root.tourCompleted();
                        }
                    }
                }
            }
        }
    }
}
