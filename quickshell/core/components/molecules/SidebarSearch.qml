// MOLÉCULA: el buscador de la barra lateral de Ajustes. Más chico que el de
// Spotlight: lupa, texto y, si escribiste algo, una ⓧ para borrarlo.
//   - Escape borra; si ya está vacío, suelta el foco.
//   - Enter avisa con accepted() (Ajustes abre el primer resultado).

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Rectangle {
    id: root

    property alias text: input.text
    property string placeholder: "Buscar"

    signal accepted()

    function focusInput(): void {
        input.forceActiveFocus();
    }

    implicitWidth: 200
    implicitHeight: 28
    radius: height / 2
    color: Theme.window.control

    // Anillo de foco en color de acento, como en macOS.
    border.width: input.activeFocus ? 2 : 0
    border.color: Qt.alpha(Theme.colors.accent, 0.55)

    Icon {
        id: lens

        anchors.left: parent.left
        anchors.leftMargin: 9
        anchors.verticalCenter: parent.verticalCenter
        icon: Theme.systemIcons.search
        size: 13
        color: Theme.window.textMuted
    }

    TextInput {
        id: input

        anchors.left: lens.right
        anchors.leftMargin: 6
        anchors.right: clear.visible ? clear.left : parent.right
        anchors.rightMargin: 6
        anchors.verticalCenter: parent.verticalCenter

        color: Theme.window.text
        selectionColor: Theme.colors.accent
        selectedTextColor: "white"
        font.family: Theme.font.ui
        font.pixelSize: Theme.window.fontBody
        clip: true
        selectByMouse: true

        onAccepted: root.accepted()

        Keys.onEscapePressed: {
            if (input.text !== "")
                input.text = "";
            else
                input.focus = false;
        }

        Text {
            anchors.verticalCenter: parent.verticalCenter
            visible: input.text === ""
            text: root.placeholder
            color: Theme.window.textMuted
            font: input.font
        }
    }

    Icon {
        id: clear

        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        visible: input.text !== ""
        icon: Theme.systemIcons.clearField
        size: 13
        color: Theme.window.textMuted

        TapHandler {
            onTapped: {
                input.text = "";
                input.forceActiveFocus();
            }
        }
    }
}
