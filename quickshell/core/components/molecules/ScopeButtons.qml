// MOLÉCULA: botones redondos con un glifo, uno elegido a la vez. Son los
// chips de Spotlight en macOS Tahoe (Aplicaciones, Archivos, Portapapeles),
// pero no saben nada de Spotlight: reciben opciones y avisan cuál tocaste.
//
// `options` es una lista de objetos con value, glyph y label. `label` no se dibuja:
// es para quien use la molécula (un tooltip, Ajustes…). El elegido se pinta
// con chosenColor (el acento); los demás, solo el glifo en contentColor.
// Al pasar el mouse, una capa de contentColor muy tenue: sirve sobre fondo
// claro (contenido oscuro) y sobre vidrio (contenido blanco).
//
// (En este comentario no van llaves: el escáner de Quickshell deja de leer
// los import en la primera línea que tenga una.)

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Row {
    id: root

    property var options: []
    property var current

    property int size: 28
    property color contentColor: Theme.colors.baseContent
    property color chosenColor: Theme.colors.accent

    signal selected(var value)

    spacing: Theme.spacing.xs

    Repeater {
        model: root.options

        Rectangle {
            id: button

            required property var modelData

            readonly property bool chosen: button.modelData.value === root.current

            width: root.size
            height: root.size
            radius: root.size / 2
            color: button.chosen ? root.chosenColor
                 : hover.hovered ? Qt.alpha(root.contentColor, 0.14)
                 : "transparent"

            Behavior on color {
                ColorAnimation { duration: 120 }
            }

            Icon {
                anchors.centerIn: parent
                icon: button.modelData.glyph
                size: Math.round(root.size * 0.5)
                color: button.chosen ? "#ffffff" : Qt.alpha(root.contentColor, 0.8)
            }

            HoverHandler {
                id: hover
                cursorShape: Qt.PointingHandCursor
            }

            TapHandler {
                onTapped: root.selected(button.modelData.value)
            }
        }
    }
}
