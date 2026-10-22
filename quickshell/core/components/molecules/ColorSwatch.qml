// MOLÉCULA: un circulito de color para elegir el acento. El elegido lleva un
// punto blanco al centro y un anillo de su mismo color, como en macOS.

import QtQuick
import qs.core.theme

Item {
    id: root

    property color tint
    property bool selected: false

    signal activated()

    implicitWidth: 22
    implicitHeight: 22

    Rectangle {
        anchors.fill: parent
        radius: width / 2
        color: "transparent"
        border.width: 2
        border.color: root.selected ? Qt.alpha(root.tint, 0.55) : "transparent"
    }

    Rectangle {
        anchors.centerIn: parent
        width: 16
        height: 16
        radius: 8
        color: root.tint
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, 0.12)
        scale: tap.pressed ? 0.88 : 1

        Behavior on scale {
            NumberAnimation {
                duration: Theme.motion.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.motion.spring
            }
        }

        Rectangle {
            anchors.centerIn: parent
            visible: root.selected
            width: 6
            height: 6
            radius: 3
            color: "white"
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tap
        onTapped: root.activated()
    }
}
