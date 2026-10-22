import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property string title: "Confirm Action"
    property string message: "Are you sure you want to proceed?"
    property string confirmText: "Confirm"
    property string cancelText: "Cancel"
    property string btnStyle: "danger"
    property var onConfirmedAction: null

    signal confirmed()
    signal cancelled()

    visible: false
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.65)
    z: 9999

    function open(dialogTitle, dialogMsg, onConfirm, btnStyleName, confirmBtnText) {
        title = dialogTitle || "Confirm Action";
        message = dialogMsg || "";
        onConfirmedAction = onConfirm;
        btnStyle = btnStyleName || "danger";
        confirmText = confirmBtnText || "Confirm";
        visible = true;
    }

    function close() {
        visible = false;
    }

    MouseArea {
        anchors.fill: parent
        onClicked: { /* Prevent click through */ }
    }

    Rectangle {
        id: card
        width: 440
        implicitHeight: contentCol.implicitHeight + 40
        radius: 10
        anchors.centerIn: parent
        color: themeManager.bgCard
        border.color: themeManager.borderPrimary
        border.width: 1

        ColumnLayout {
            id: contentCol
            anchors.fill: parent
            anchors.margins: 24
            spacing: 16

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Text {
                    text: root.btnStyle === "danger" ? "⚠️" : "ℹ️"
                    font.pixelSize: 20
                }

                Text {
                    text: root.title
                    color: themeManager.textPrimary
                    font.pixelSize: 16
                    font.weight: Font.Bold
                    Layout.fillWidth: true
                }
            }

            Text {
                text: root.message
                color: themeManager.textSecondary
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
                lineHeight: 1.3
            }

            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: themeManager.borderPrimary
            }

            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                Item { Layout.fillWidth: true }

                ActionButton {
                    text: root.cancelText
                    btnStyle: "subtle"
                    onClicked: {
                        root.close();
                        root.cancelled();
                    }
                }

                ActionButton {
                    text: root.confirmText
                    btnStyle: root.btnStyle
                    onClicked: {
                        root.close();
                        if (root.onConfirmedAction) {
                            root.onConfirmedAction();
                        }
                        root.confirmed();
                    }
                }
            }
        }
    }
}
