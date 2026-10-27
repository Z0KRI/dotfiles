// MOLÉCULA: botones redondos con un glifo, uno elegido a la vez. Son los
// chips de Spotlight en macOS Tahoe (Aplicaciones, Archivos, Portapapeles),
// pero no saben nada de Spotlight: reciben opciones y avisan cuál tocaste.
//
// `options` es una lista de objetos con value, glyph y label. `label` no se dibuja:
// es para quien use la molécula (un tooltip, Ajustes…). El elegido se pinta
// con el color de acento; los demás, solo el glifo.
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
            color: button.chosen ? Theme.colors.accent
                 : hover.hovered ? Qt.alpha(Theme.colors.baseContent, 0.12)
                 : "transparent"

            Behavior on color {
                ColorAnimation { duration: 120 }
            }

            Icon {
                anchors.centerIn: parent
                icon: button.modelData.glyph
                size: Math.round(root.size * 0.5)
                color: button.chosen ? "#ffffff" : Qt.alpha(Theme.colors.baseContent, 0.75)
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
