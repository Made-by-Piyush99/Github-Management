import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string message: ""
    property string type: "info" // success, error, warning, info
    property bool showing: false

    function show(msg, toastType) {
        message = msg || "";
        type = toastType || "info";
        showing = true;
        dismissTimer.restart();
    }

    function dismiss() {
        showing = false;
    }

    Timer {
        id: dismissTimer
        interval: 3500
        repeat: false
        onTriggered: root.dismiss()
    }

    Rectangle {
        id: toastBox
        width: Math.min(480, msgLabel.implicitWidth + 60)
        height: 42
        radius: 8
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.showing ? 24 : -60
        opacity: root.showing ? 1.0 : 0.0

        Behavior on anchors.bottomMargin { NumberAnimation { duration: 250; easing.type: Easing.OutCubic } }
        Behavior on opacity { NumberAnimation { duration: 200 } }

        color: themeManager.isDark ? Qt.rgba(19/255, 27/255, 43/255, 0.96) : themeManager.bgCard

        border.color: {
            if (root.type === "success") return themeManager.success;
            if (root.type === "error") return themeManager.danger;
            if (root.type === "warning") return themeManager.warning;
            return themeManager.borderSecondary;
        }
        border.width: 1

        Row {
            anchors.centerIn: parent
            spacing: 8

            AppIcon {
                name: root.type === "success" ? "check" : (root.type === "error" ? "shield" : "guide")
                size: 14
                color: {
                    if (root.type === "success") return themeManager.success;
                    if (root.type === "error") return themeManager.danger;
                    if (root.type === "warning") return themeManager.warning;
                    return themeManager.accent;
                }
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                id: msgLabel
                text: root.message
                color: themeManager.textPrimary
                font.pixelSize: 12
                font.weight: Font.Medium
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                maximumLineCount: 1
            }
        }
    }
}
