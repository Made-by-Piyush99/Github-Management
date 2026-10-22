import QtQuick
import QtQuick.Controls

Item {
    id: root

    property string text: ""
    property string iconText: ""
    property string btnStyle: "secondary" // primary, secondary, danger, subtle
    property bool small: false
    property bool busy: false
    property bool enabled: true

    signal clicked()

    implicitWidth: btnRow.implicitWidth + (small ? 16 : 24)
    implicitHeight: small ? 28 : 34

    opacity: root.enabled ? 1.0 : 0.5

    function getBgColor() {
        if (!root.enabled) return themeManager.borderPrimary;
        if (mouseArea.pressed) {
            if (btnStyle === "primary") return Qt.darker(themeManager.accent, 1.2);
            if (btnStyle === "danger") return Qt.darker(themeManager.danger, 1.2);
            return themeManager.borderSecondary;
        }
        if (mouseArea.containsMouse) {
            if (btnStyle === "primary") return themeManager.accentHover;
            if (btnStyle === "danger") return Qt.lighter(themeManager.danger, 1.1);
            if (btnStyle === "subtle") return themeManager.bgCardHover;
            return themeManager.bgCardHover;
        }
        if (btnStyle === "primary") return themeManager.accent;
        if (btnStyle === "danger") return themeManager.danger;
        if (btnStyle === "subtle") return "transparent";
        return themeManager.bgCard;
    }

    function getFgColor() {
        if (btnStyle === "primary" || btnStyle === "danger") return "#FFFFFF";
        if (mouseArea.containsMouse) return themeManager.textPrimary;
        return themeManager.textSecondary;
    }

    Rectangle {
        id: bgRect
        anchors.fill: parent
        radius: 6
        color: root.getBgColor()
        border.color: (root.btnStyle === "primary" || root.btnStyle === "subtle") ? "transparent" : themeManager.borderPrimary
        border.width: 1

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        Row {
            id: btnRow
            anchors.centerIn: parent
            spacing: 6

            Text {
                visible: root.iconText !== "" && !root.busy
                text: root.iconText
                color: root.getFgColor()
                font.pixelSize: root.small ? 12 : 14
                anchors.verticalCenter: parent.verticalCenter
            }

            BusyIndicator {
                visible: root.busy
                running: root.busy
                width: root.small ? 14 : 16
                height: width
                anchors.verticalCenter: parent.verticalCenter
            }

            Text {
                visible: root.text !== ""
                text: root.text
                color: root.getFgColor()
                font.pixelSize: root.small ? 12 : 13
                font.weight: root.btnStyle === "primary" ? Font.DemiBold : Font.Normal
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onClicked: {
                if (root.enabled && !root.busy) {
                    root.clicked();
                }
            }
        }
    }
}
