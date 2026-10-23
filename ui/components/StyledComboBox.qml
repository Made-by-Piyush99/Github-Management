import QtQuick
import QtQuick.Controls

ComboBox {
    id: control

    implicitWidth: 200
    implicitHeight: 36

    property color customBg: "transparent"
    property int customRadius: 7

    delegate: ItemDelegate {
        id: itemDelegate
        width: ListView.view.width
        height: 34
        padding: 8

        contentItem: Row {
            spacing: 8
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 10
            anchors.right: parent.right
            anchors.rightMargin: 10

            AppIcon {
                visible: control.currentIndex === index
                name: "check"
                size: 13
                color: themeManager.accent
                anchors.verticalCenter: parent.verticalCenter
            }

            Item {
                visible: control.currentIndex !== index
                width: 13
                height: 13
            }

            Text {
                text: control.textRole ? (Array.isArray(control.model) ? modelData[control.textRole] : model[control.textRole]) : modelData
                color: itemDelegate.highlighted ? themeManager.accent : themeManager.textPrimary
                font.pixelSize: 12
                font.weight: control.currentIndex === index ? Font.DemiBold : Font.Normal
                elide: Text.ElideRight
                width: parent.width - 24
                anchors.verticalCenter: parent.verticalCenter
            }
        }

        background: Rectangle {
            color: itemDelegate.highlighted ? themeManager.accentMuted : "transparent"
            radius: 5
        }
    }

    indicator: Item {
        x: control.width - width - control.rightPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: 16
        height: 16

        Canvas {
            id: chevronCanvas
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d");
                ctx.clearRect(0, 0, width, height);
                ctx.strokeStyle = control.hovered || control.popup.visible ? themeManager.accent : themeManager.textMuted;
                ctx.lineWidth = 1.8;
                ctx.lineCap = "round";
                ctx.lineJoin = "round";
                ctx.beginPath();
                if (control.popup.visible) {
                    // Chevron Up
                    ctx.moveTo(4, 10);
                    ctx.lineTo(8, 6);
                    ctx.lineTo(12, 10);
                } else {
                    // Chevron Down
                    ctx.moveTo(4, 6);
                    ctx.lineTo(8, 10);
                    ctx.lineTo(12, 6);
                }
                ctx.stroke();
            }

            Connections {
                target: control
                function onHoveredChanged() { chevronCanvas.requestPaint(); }
            }
            Connections {
                target: control.popup
                function onVisibleChanged() { chevronCanvas.requestPaint(); }
            }
        }
    }

    contentItem: Text {
        leftPadding: 12
        rightPadding: control.indicator.width + 12
        text: control.displayText
        font.pixelSize: 12
        font.weight: Font.Medium
        color: themeManager.textPrimary
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Rectangle {
        implicitWidth: 160
        implicitHeight: 36
        radius: control.customRadius

        // Modern translucent glass background
        color: {
            if (control.customBg !== "transparent") return control.customBg;
            if (control.down || control.popup.visible) {
                return themeManager.isDark ? Qt.rgba(56/255, 189/255, 248/255, 0.12) : Qt.rgba(2, 132, 199, 0.08);
            }
            if (control.hovered) {
                return themeManager.isDark ? Qt.rgba(255, 255, 255, 0.07) : Qt.rgba(0, 0, 0, 0.05);
            }
            return themeManager.isDark ? Qt.rgba(255, 255, 255, 0.035) : Qt.rgba(0, 0, 0, 0.025);
        }

        border.color: {
            if (control.popup.visible || control.activeFocus) {
                return themeManager.accent;
            }
            if (control.hovered) {
                return themeManager.borderSecondary;
            }
            return themeManager.isDark ? Qt.rgba(255, 255, 255, 0.12) : themeManager.borderPrimary;
        }
        border.width: 1

        Behavior on color { ColorAnimation { duration: 120 } }
        Behavior on border.color { ColorAnimation { duration: 120 } }
    }

    popup: Popup {
        y: control.height + 4
        width: control.width
        implicitHeight: Math.min(220, contentItem.implicitHeight + 16)
        padding: 6

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.popup.visible ? control.delegateModel : null
            currentIndex: control.highlightedIndex
            boundsBehavior: Flickable.StopAtBounds

            ScrollBar.vertical: ScrollBar {
                policy: ScrollBar.AsNeeded
            }
        }

        background: Rectangle {
            radius: 8
            color: themeManager.isDark ? "#141B26" : "#FFFFFF"
            border.color: themeManager.borderPrimary
            border.width: 1

            // Subtle drop shadow line
            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                height: 1
                color: Qt.rgba(255, 255, 255, 0.08)
                visible: themeManager.isDark
            }
        }
    }
}
