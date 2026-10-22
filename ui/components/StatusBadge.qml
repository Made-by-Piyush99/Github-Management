import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    property string status: "Unknown"
    property bool small: false

    function getBadgeBg(st) {
        var s = (st || "").toLowerCase();
        if (s.indexOf("sync") !== -1) return themeManager.isDark ? "#143D24" : "#DCFCE7";
        if (s.indexOf("modified") !== -1) return themeManager.isDark ? "#3D2B14" : "#FEF3C7";
        if (s.indexOf("ahead") !== -1) return themeManager.isDark ? "#1E293B" : "#E0F2FE";
        if (s.indexOf("behind") !== -1) return themeManager.isDark ? "#3D1E14" : "#FFEDD5";
        if (s.indexOf("conflict") !== -1 || s.indexOf("error") !== -1) return themeManager.isDark ? "#3D1414" : "#FEE2E2";
        if (s.indexOf("empty") !== -1 || s.indexOf("no remote") !== -1) return themeManager.isDark ? "#262C38" : "#F3F4F6";
        return themeManager.isDark ? "#262C38" : "#F3F4F6";
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

    implicitWidth: label.implicitWidth + (small ? 12 : 16)
    implicitHeight: small ? 20 : 26
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
