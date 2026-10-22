import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property var diffData: null // Parsed diff object with files array
    property string rawDiff: ""

    color: themeManager.bgPrimary
    border.color: themeManager.borderPrimary
    border.width: 1
    radius: 6
    clip: true

    ScrollView {
        anchors.fill: parent
        anchors.margins: 8

        Column {
            width: parent.width
            spacing: 12

            // If empty
            Text {
                visible: (!root.diffData || !root.diffData.files || root.diffData.files.length === 0) && !root.rawDiff
                text: "No diff content to display. Select a modified file to inspect changes."
                color: themeManager.textMuted
                font.pixelSize: 13
                anchors.horizontalCenter: parent.horizontalCenter
                topPadding: 40
            }

            // Render structured hunks if available
            Repeater {
                model: (root.diffData && root.diffData.files) ? root.diffData.files : []

                Column {
                    width: root.width - 24
                    spacing: 6

                    // File Header
                    Rectangle {
                        width: parent.width
                        height: 32
                        color: themeManager.bgCard
                        radius: 4
                        border.color: themeManager.borderPrimary
                        border.width: 1

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 12
                            anchors.rightMargin: 12
                            spacing: 8

                            Text {
                                text: modelData.status === "added" ? "➕" : (modelData.status === "deleted" ? "➖" : "📝")
                                font.pixelSize: 13
                            }

                            Text {
                                text: modelData.new_path || modelData.old_path
                                color: themeManager.textPrimary
                                font.pixelSize: 13
                                font.weight: Font.DemiBold
                                Layout.fillWidth: true
                            }

                            Text {
                                text: modelData.status.toUpperCase()
                                color: modelData.status === "added" ? themeManager.success : (modelData.status === "deleted" ? themeManager.danger : themeManager.warning)
                                font.pixelSize: 11
                                font.weight: Font.Medium
                            }
                        }
                    }

                    // Hunks
                    Repeater {
                        model: modelData.hunks || []

                        Column {
                            width: parent.width
                            spacing: 1

                            // Hunk Header
                            Rectangle {
                                width: parent.width
                                height: 26
                                color: themeManager.isDark ? "#1E293B" : "#E2E8F0"
                                radius: 2

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    spacing: 8

                                    Text {
                                        text: modelData.header
                                        color: themeManager.accent
                                        font.family: "Consolas, JetBrains Mono, monospace"
                                        font.pixelSize: 11
                                    }

                                    Text {
                                        visible: !!modelData.section
                                        text: modelData.section
                                        color: themeManager.textMuted
                                        font.pixelSize: 11
                                    }
                                }
                            }

                            // Diff Lines
                            Repeater {
                                model: modelData.lines || []

                                Rectangle {
                                    width: parent.width
                                    height: 22
                                    color: {
                                        if (modelData.type === "add") return themeManager.isDark ? "#143D24" : "#E6F4EA";
                                        if (modelData.type === "del") return themeManager.isDark ? "#3D1414" : "#FCE8E6";
                                        return "transparent";
                                    }

                                    RowLayout {
                                        anchors.fill: parent
                                        spacing: 6

                                        // Old line number
                                        Text {
                                            Layout.preferredWidth: 40
                                            horizontalAlignment: Text.AlignRight
                                            text: modelData.old_line !== null ? modelData.old_line : ""
                                            color: themeManager.textMuted
                                            font.family: "Consolas, monospace"
                                            font.pixelSize: 11
                                        }

                                        // New line number
                                        Text {
                                            Layout.preferredWidth: 40
                                            horizontalAlignment: Text.AlignRight
                                            text: modelData.new_line !== null ? modelData.new_line : ""
                                            color: themeManager.textMuted
                                            font.family: "Consolas, monospace"
                                            font.pixelSize: 11
                                        }

                                        // Marker (+ / - / space)
                                        Text {
                                            Layout.preferredWidth: 16
                                            horizontalAlignment: Text.AlignHCenter
                                            text: modelData.type === "add" ? "+" : (modelData.type === "del" ? "-" : " ")
                                            color: modelData.type === "add" ? themeManager.success : (modelData.type === "del" ? themeManager.danger : themeManager.textMuted)
                                            font.family: "Consolas, monospace"
                                            font.pixelSize: 12
                                            font.weight: Font.Bold
                                        }

                                        // Content line
                                        Text {
                                            Layout.fillWidth: true
                                            text: modelData.content
                                            color: modelData.type === "del" ? themeManager.danger : (modelData.type === "add" ? themeManager.success : themeManager.textPrimary)
                                            font.family: "Consolas, JetBrains Mono, monospace"
                                            font.pixelSize: 12
                                            elide: Text.ElideNone
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
