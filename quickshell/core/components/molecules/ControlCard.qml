// MOLÉCULA: tarjeta grande del Centro de control (ej. No molestar).
// Círculo arriba; título y estado abajo. Tocar cualquier parte cambia el estado.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Surface {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false

    signal toggled()

    implicitWidth: 150
    implicitHeight: 130
    radius: Theme.glass.tileRadius
    border.width: 1
    border.color: Theme.glass.border
    color: hover.hovered ? Theme.glass.tileHover : Theme.glass.tile
    scale: tap.pressed ? 0.97 : 1

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    Behavior on scale {
        NumberAnimation {
            duration: Theme.motion.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.motion.spring
        }
    }

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 14
        width: 40
        height: 40
        radius: 20
        color: root.active ? Theme.glass.controlOn : Theme.glass.control

        Behavior on color {
            ColorAnimation { duration: Theme.motion.duration }
        }

        Icon {
            anchors.centerIn: parent
            icon: root.icon
            size: 18
            color: root.active ? Theme.colors.accent : Theme.glass.content
        }
    }

    Column {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        anchors.margins: 14

        Label {
            width: parent.width
            text: root.title
            color: Theme.glass.content
            font.pixelSize: Theme.font.normal
            font.weight: Font.DemiBold
            elide: Text.ElideRight
        }

        Label {
            width: parent.width
            visible: root.subtitle !== ""
            text: root.subtitle
            color: Theme.glass.contentMuted
            font.pixelSize: Theme.font.small
            elide: Text.ElideRight
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tap
        onTapped: root.toggled()
    }
}