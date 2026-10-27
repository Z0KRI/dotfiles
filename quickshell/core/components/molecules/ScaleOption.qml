// MOLÉCULA: una opción de "Tamaño" en Pantallas, como las de macOS: una
// ventanita con "Aa" (más grande mientras más grande es la escala) y debajo
// cómo se ve el escritorio con ella ("2048 × 1152").
//
// `weight` va de 0 (más espacio: letra chica) a 1 (texto más grande).

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Item {
    id: root

    property real weight: 0.5
    property string text: ""
    property bool selected: false

    signal activated()

    implicitWidth: 74
    implicitHeight: thumb.height + 6 + label.implicitHeight

    Rectangle {
        id: thumb

        anchors.horizontalCenter: parent.horizontalCenter
        width: 64
        height: 44
        radius: 8
        color: Theme.window.control
        border.width: root.selected ? 2.5 : 1
        border.color: root.selected ? Theme.colors.accent : Theme.window.controlBorder

        Label {
            anchors.centerIn: parent
            text: "Aa"
            color: Theme.window.text
            font.pixelSize: Math.round(9 + root.weight * 13)
            font.weight: Font.DemiBold
        }
    }

    Label {
        id: label

        anchors.top: thumb.bottom
        anchors.topMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.text
        color: root.selected ? Theme.window.text : Theme.window.textMuted
        font.pixelSize: Theme.window.fontCaption
        font.weight: root.selected ? Font.DemiBold : Font.Normal
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.activated()
    }
}
