import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    property string title: ""
    property string value: "0"
    property string subtext: ""
    property string iconText: "📊"
    property color highlightColor: themeManager.accent
    property bool isWarning: false

    implicitWidth: 200
    implicitHeight: 96
    radius: 8
    color: themeManager.bgCard
    border.color: isWarning ? Qt.rgba(themeManager.warning.r, themeManager.warning.g, themeManager.warning.b, 0.4) : themeManager.borderPrimary
    border.width: 1

    Behavior on color {
        ColorAnimation { duration: 150 }
    }

    Item {
        anchors.fill: parent
        anchors.margins: 14

        Row {
            anchors.fill: parent
            spacing: 12

            Rectangle {
                width: 38
                height: 38
                radius: 8
                color: Qt.rgba(root.highlightColor.r, root.highlightColor.g, root.highlightColor.b, 0.12)
                anchors.verticalCenter: parent.verticalCenter

                Text {
                    anchors.centerIn: parent
                    text: root.iconText
                    font.pixelSize: 18
                }
            }

            Column {
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2
                width: parent.width - 50

                Text {
                    text: root.title
                    color: themeManager.textSecondary
                    font.pixelSize: 11
                    font.weight: Font.Medium
                    elide: Text.ElideRight
                    width: parent.width
                }

                Text {
                    text: root.value
                    color: root.isWarning ? themeManager.warning : themeManager.textPrimary
                    font.pixelSize: 22
                    font.weight: Font.Bold
                }

                Text {
                    visible: root.subtext !== ""
                    text: root.subtext
                    color: themeManager.textMuted
                    font.pixelSize: 10
                    elide: Text.ElideRight
                    width: parent.width
                }
            }
        }
    }
}
