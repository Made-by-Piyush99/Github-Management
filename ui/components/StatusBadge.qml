import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    property string status: "Unknown"
    property bool small: false

    function getBadgeBg(st) {
        var fg = getBadgeFg(st);
        return themeManager.isDark ? Qt.rgba(fg.r, fg.g, fg.b, 0.14) : Qt.rgba(fg.r, fg.g, fg.b, 0.1);
    }

    function getBadgeFg(st) {
        var s = (st || "").toLowerCase();
        if (s.indexOf("sync") !== -1) return themeManager.success;
        if (s.indexOf("modified") !== -1) return themeManager.warning;
        if (s.indexOf("ahead") !== -1) return themeManager.accent;
        if (s.indexOf("behind") !== -1) return themeManager.warning;
        if (s.indexOf("conflict") !== -1 || s.indexOf("error") !== -1) return themeManager.danger;
        return themeManager.textSecondary;
    }

    implicitWidth: label.implicitWidth + (small ? 14 : 18)
    implicitHeight: small ? 22 : 26
    radius: height / 2
    color: getBadgeBg(status)
    border.color: Qt.rgba(getBadgeFg(status).r, getBadgeFg(status).g, getBadgeFg(status).b, 0.3)
    border.width: 1

    Row {
        anchors.centerIn: parent
        spacing: 5

        Rectangle {
            width: small ? 5 : 6
            height: width
            radius: width / 2
            color: getBadgeFg(root.status)
            anchors.verticalCenter: parent.verticalCenter
        }

        Text {
            id: label
            text: root.status
            color: getBadgeFg(root.status)
            font.pixelSize: root.small ? 11 : 12
            font.weight: Font.Medium
            anchors.verticalCenter: parent.verticalCenter
        }
    }
}
