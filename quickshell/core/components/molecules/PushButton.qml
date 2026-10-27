// MOLÉCULA: botón de Ajustes (el "push button" de macOS, en cápsula como en
// Tahoe). Tres estilos:
//   - normal:      blanco (o gris en oscuro) con borde fino.
//   - primary:     color de acento con texto blanco, para la acción principal.
//   - destructive: texto rojo, para borrar u olvidar.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Rectangle {
    id: root

    property string text: ""
    property bool primary: false
    property bool destructive: false

    signal clicked()

    implicitWidth: label.implicitWidth + 24
    implicitHeight: 24
    radius: height / 2
    opacity: root.enabled ? 1 : 0.45

    color: root.primary ? Theme.colors.accent : Theme.window.controlRaised
    border.width: root.primary ? 0 : 1
    border.color: Theme.window.controlBorder

    // Al presionar, una capa oscura encima: sirve igual para los tres estilos.
    Rectangle {
        anchors.fill: parent
        radius: parent.radius
        color: Qt.rgba(0, 0, 0, tap.pressed ? 0.12 : 0)
    }

    Label {
        id: label

        anchors.centerIn: parent
        text: root.text
        font.pixelSize: Theme.window.fontBody - 1
        font.weight: Font.Medium
        color: {
            if (root.primary)
                return "white";
            if (root.destructive)
                return Theme.window.destructive;
            return Theme.window.text;
        }
    }

    HoverHandler {
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tap
        enabled: root.enabled
        onTapped: root.clicked()
    }
}
