// MOLÉCULA: botón redondo de vidrio (accesos rápidos, regresar).
// Encendido: círculo blanco con el ícono en color de acento, como en macOS.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Surface {
    id: root

    property string icon: ""
    property int iconSize: 20
    property bool active: false

    signal clicked()

    implicitWidth: 60
    implicitHeight: 60
    radius: width / 2
    border.width: 1
    border.color: Theme.glass.border

    color: {
        if (root.active)
            return Theme.glass.controlOn;
        if (hover.hovered)
            return Theme.glass.tileHover;
        return Theme.glass.tile;
    }

    scale: tap.pressed ? 0.92 : 1

    Behavior on color {
        ColorAnimation { duration: 140 }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.motion.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.motion.spring
        }
    }

    Icon {
        anchors.centerIn: parent
        icon: root.icon
        size: root.iconSize
        color: root.active ? Theme.colors.accent : Theme.glass.content
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tap
        onTapped: root.clicked()
    }
}