// MOLÉCULA: píldora del Centro de control (Wi-Fi, Bluetooth, iPhone...).
// El círculo enciende y apaga; el texto abre el detalle. Si no hay
// detalle, tocar cualquier parte enciende y apaga.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Surface {
    id: root

    property string icon: ""
    property string title: ""
    property string subtitle: ""
    property bool active: false
    property bool hasDetail: true

    signal toggled()
    signal opened()

    implicitWidth: 150
    implicitHeight: 60
    radius: height / 2
    border.width: 1
    border.color: Theme.glass.border
    color: rowHover.hovered ? Theme.glass.tileHover : Theme.glass.tile
    opacity: root.enabled ? 1 : 0.45

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    // Detector de hover de toda la píldora (ancestro de los demás).
    HoverHandler {
        id: rowHover
    }

    // Círculo: enciende y apaga.
    Rectangle {
        id: circle

        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter
        width: root.height - 20
        height: width
        radius: width / 2
        color: root.active ? Theme.glass.controlOn : Theme.glass.control
        scale: circleTap.pressed ? 0.9 : 1

        Behavior on color {
            ColorAnimation { duration: Theme.motion.duration }
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
            size: 17
            color: root.active ? Theme.colors.accent : Theme.glass.content
        }

        HoverHandler {
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            id: circleTap
            onTapped: root.toggled()
        }
    }

    // Texto: abre el detalle (o enciende/apaga si no hay detalle).
    Item {
        anchors.left: circle.right
        anchors.leftMargin: 10
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        Column {
            anchors.left: parent.left
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter

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
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: {
                if (root.hasDetail)
                    root.opened();
                else
                    root.toggled();
            }
        }
    }
}