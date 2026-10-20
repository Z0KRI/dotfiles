// MOLÉCULA: opción de una lista de "elige una" (salidas de audio,
// redes Wi-Fi, dispositivos Bluetooth). Estilo Tahoe: el ícono va en un
// círculo que se pinta de acento cuando la opción está elegida.
// Opcionales: subtítulo (segunda línea) e ícono a la derecha (ej. candado).

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Surface {
    id: root

    property string icon: ""
    property string text: ""
    property string subtitle: ""
    property string trailingIcon: ""
    property bool selected: false

    // Color de texto e íconos: el del tema en menús, blanco sobre vidrio.
    property color contentColor: Theme.colors.base800

    signal triggered()

    width: parent ? parent.width : implicitWidth
    implicitWidth: 240
    implicitHeight: root.subtitle !== "" ? 44 : 36
    radius: 10

    color: hover.hovered
           ? Qt.alpha(root.contentColor, 0.1)
           : Qt.alpha(root.contentColor, 0)

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    // Círculo del ícono: acento si está elegida, tenue si no.
    Rectangle {
        id: badge

        anchors.left: parent.left
        anchors.leftMargin: Theme.spacing.sm
        anchors.verticalCenter: parent.verticalCenter
        width: 26
        height: 26
        radius: 13
        color: root.selected ? Theme.colors.accent : Qt.alpha(root.contentColor, 0.15)

        Behavior on color {
            ColorAnimation { duration: Theme.motion.duration }
        }

        Icon {
            anchors.centerIn: parent
            icon: root.icon
            size: 13
            color: root.selected ? Theme.glass.controlOn : root.contentColor
        }
    }

    Column {
        anchors.left: badge.right
        anchors.leftMargin: Theme.spacing.sm
        anchors.right: trailing.visible ? trailing.left : parent.right
        anchors.rightMargin: Theme.spacing.sm
        anchors.verticalCenter: parent.verticalCenter

        Label {
            width: parent.width
            text: root.text
            color: root.contentColor
            elide: Text.ElideRight
            font.weight: root.selected ? Font.DemiBold : Font.Normal
        }

        Label {
            width: parent.width
            visible: root.subtitle !== ""
            text: root.subtitle
            color: root.contentColor
            opacity: 0.6
            font.pixelSize: Theme.font.small
            elide: Text.ElideRight
        }
    }

    Icon {
        id: trailing

        visible: root.trailingIcon !== ""
        anchors.right: parent.right
        anchors.rightMargin: Theme.spacing.sm
        anchors.verticalCenter: parent.verticalCenter
        icon: root.trailingIcon
        size: 12
        color: root.contentColor
        opacity: 0.5
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.triggered()
    }
}