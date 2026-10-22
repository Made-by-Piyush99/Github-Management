import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Rectangle {
    id: root

    property string title: "Input Required"
    property string prompt: "Enter value:"
    property string placeholder: ""
    property string initialValue: ""
    property string confirmText: "Submit"
    property string errorText: ""
    property bool isPassword: false
    property var onSubmittedAction: null

    signal submitted(string text)
    signal cancelled()

    visible: false
    anchors.fill: parent
    color: Qt.rgba(0, 0, 0, 0.65)
    z: 9999

    function open(dTitle, dPrompt, dPlaceholder, dInitVal, onSubmit, isPass) {
        title = dTitle || "Input";
        prompt = dPrompt || "";
        placeholder = dPlaceholder || "";
        initialValue = dInitVal || "";
        inputField.text = initialValue;
        onSubmittedAction = onSubmit;
        isPassword = !!isPass;
        errorText = "";
        visible = true;
        inputField.forceActiveFocus();
    }

    function close() {
        visible = false;
        errorText = "";
    }

    MouseArea {
        anchors.fill: parent
        onClicked: { /* Prevent click through */ }
    }

    Rectangle {
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

            Text {
                text: root.title
                color: themeManager.textPrimary
                font.pixelSize: 16
                font.weight: Font.Bold
                Layout.fillWidth: true
            }

            Text {
                text: root.prompt
                color: themeManager.textSecondary
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            Rectangle {
                Layout.fillWidth: true
                height: 38
                radius: 6
                color: themeManager.bgInput
                border.color: root.errorText ? themeManager.danger : (inputField.activeFocus ? themeManager.accent : themeManager.borderPrimary)
                border.width: 1

                TextField {
                    id: inputField
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    color: themeManager.textPrimary
                    font.pixelSize: 13
                    placeholderText: root.placeholder
                    echoMode: root.isPassword ? TextInput.Password : TextInput.Normal
                    background: null
                    selectByMouse: true
                    onAccepted: submitBtn.clicked()
                }
            }

            Text {
                visible: root.errorText !== ""
                text: root.errorText
                color: themeManager.danger
                font.pixelSize: 11
                Layout.fillWidth: true
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
                    text: "Cancel"
                    btnStyle: "subtle"
                    onClicked: {
                        root.close();
                        root.cancelled();
                    }
                }

                ActionButton {
                    id: submitBtn
                    text: root.confirmText
                    btnStyle: "primary"
                    onClicked: {
                        var val = inputField.text.trim();
                        if (!val) {
                            root.errorText = "This field cannot be empty.";
                            return;
                        }
                        root.close();
                        if (root.onSubmittedAction) {
                            root.onSubmittedAction(val);
                        }
                        root.submitted(val);
                    }
                }
            }
        }
    }
}
