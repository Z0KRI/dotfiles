// MOLÉCULA: opción de una lista de "elige una" (salidas de audio,
// redes Wi-Fi, dispositivos Bluetooth). Estilo Tahoe: el ícono va en un
// círculo que se pinta de acento cuando la opción está elegida.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Surface {
    id: root

    property string icon: ""
    property string text: ""
    property bool selected: false

    signal triggered()

    width: parent ? parent.width : implicitWidth
    implicitHeight: 36
    implicitWidth: row.implicitWidth + Theme.spacing.sm * 2
    radius: 8

    color: hover.hovered
           ? Qt.alpha(Theme.colors.base800, 0.08)
           : Qt.alpha(Theme.colors.base800, 0)

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    Row {
        id: row

        anchors.left: parent.left
        anchors.leftMargin: Theme.spacing.sm
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.spacing.sm

        // Círculo del ícono: acento si está elegida, gris si no.
        Rectangle {
            id: badge

            width: 26
            height: 26
            radius: 13
            color: root.selected ? Theme.colors.accent : Qt.alpha(Theme.colors.base800, 0.12)

            Behavior on color {
                ColorAnimation { duration: Theme.motion.duration }
            }

            Icon {
                anchors.centerIn: parent
                icon: root.icon
                size: 13
                color: root.selected ? Theme.colors.base100 : Theme.colors.base800
            }
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            // No más ancho que la fila: los nombres largos se recortan con "…".
            width: Math.min(implicitWidth, root.width - badge.width - Theme.spacing.sm * 3)
            text: root.text
            elide: Text.ElideRight
            font.weight: root.selected ? Font.DemiBold : Font.Normal
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.triggered()
    }
}