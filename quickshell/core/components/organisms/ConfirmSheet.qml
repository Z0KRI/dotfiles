// ORGANISMO: hoja de confirmación modal: título, mensaje y dos botones.
// Enter = aceptar, Escape = rechazar. Lo modal (oscurecer, bloquear clics,
// la tarjeta) es de Sheet; aquí solo va lo que lleva adentro.

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules

Sheet {
    id: root

    property string icon: ""
    property color tint: Theme.colors.accent
    property string title: ""
    property string message: ""
    property string acceptText: "Aceptar"
    property string rejectText: "Cancelar"

    signal accepted()
    signal rejected()

    onReturnPressed: root.accepted()
    onEscapePressed: root.rejected()

    SymbolTile {
        visible: root.icon !== ""
        anchors.horizontalCenter: parent.horizontalCenter
        size: 44
        icon: root.icon
        tint: root.tint
    }

    Label {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: root.title
        color: Theme.window.text
        font.pixelSize: Theme.window.fontTitle
        font.weight: Font.Bold
    }

    Label {
        width: parent.width
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.WordWrap
        text: root.message
        color: Theme.window.textMuted
        font.pixelSize: Theme.window.fontBody - 1
    }

    Item {
        width: 1
        height: 4
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: 10

        PushButton {
            width: 140
            text: root.rejectText
            onClicked: root.rejected()
        }

        PushButton {
            width: 140
            primary: true
            text: root.acceptText
            onClicked: root.accepted()
        }
    }
}
