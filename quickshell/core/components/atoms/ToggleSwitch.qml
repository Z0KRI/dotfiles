// ÁTOMO: interruptor estilo macOS / iOS.
// No cambia solo: avisa con toggled() y quien lo usa cambia el estado real;
// "checked" refleja ese estado.

import QtQuick
import qs.core.theme

Rectangle {
    id: root

    property bool checked: false
    property color onColor: Theme.colors.accent
    property color offColor: Qt.alpha(Theme.colors.base800, 0.2)

    signal toggled()

    implicitWidth: 38
    implicitHeight: 22
    radius: height / 2
    color: root.checked ? root.onColor : root.offColor

    Behavior on color {
        ColorAnimation { duration: 160 }
    }

    // La perilla: blanca en ambos modos, como en macOS.
    Rectangle {
        width: root.height - 4
        height: width
        radius: width / 2
        y: 2
        x: root.checked ? root.width - width - 2 : 2
        color: Theme.glass.controlOn

        Behavior on x {
            NumberAnimation {
                duration: Theme.motion.duration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.motion.spring
            }
        }
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.toggled()
    }
}