// MOLÉCULA: un botón chico que se queda encendido o apagado (ej. los números
// de escritorio). Encendido: color de acento con texto blanco.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Rectangle {
    id: root

    property string text: ""
    property bool checked: false

    signal toggled()

    implicitWidth: Math.max(26, label.implicitWidth + 14)
    implicitHeight: 26
    radius: 7

    color: root.checked ? Theme.colors.accent : Theme.window.control

    Behavior on color {
        ColorAnimation { duration: 140 }
    }

    Label {
        id: label

        anchors.centerIn: parent
        text: root.text
        color: root.checked ? "white" : Theme.window.text
        font.pixelSize: Theme.window.fontBody - 1
        font.weight: Font.Medium
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.toggled()
    }
}
