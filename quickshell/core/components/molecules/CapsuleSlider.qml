// MOLÉCULA: deslizador en forma de cápsula, estilo Centro de control
// de macOS Tahoe / iOS. Con un ícono dentro de la pista, a la izquierda.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Item {
    id: root

    // Valor de 0 a 1.
    property real value: 0
    property string icon: ""
    property real wheelStep: 0.05

    // Se emite al arrastrar, hacer clic o usar la rueda.
    signal moved(real value)

    implicitWidth: 240
    implicitHeight: 28

    // Mientras arrastras, se muestra tu posición, no la del sistema.
    property real dragValue: 0
    readonly property real shownValue: mouse.pressed ? root.dragValue : root.value

    // Al presionarlo crece un poco con tu rebote, como en iOS.
    scale: mouse.pressed ? 1.03 : 1

    Behavior on scale {
        NumberAnimation {
            duration: Theme.motion.duration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.motion.spring
        }
    }

    Rectangle {
        id: track

        anchors.fill: parent
        radius: height / 2
        color: Qt.alpha(Theme.colors.base800, 0.15)

        Rectangle {
            id: fill

            height: parent.height
            // En 0 queda un círculo (donde vive el ícono); en 1, la pista completa.
            width: height + root.shownValue * (parent.width - height)
            radius: height / 2
            color: Theme.colors.base100

            // Anima los cambios que llegan del sistema, no los de tu dedo.
            Behavior on width {
                enabled: !mouse.pressed
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }
        }

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            x: (parent.height - width) / 2
            visible: root.icon !== ""
            icon: root.icon
            size: 14
            color: Theme.colors.base800
        }
    }

    MouseArea {
        id: mouse

        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor

        // Convierte la posición del mouse en un valor de 0 a 1,
        // con el mismo mapeo que el relleno.
        function update(x): void {
            const usable = width - height;
            const value = Math.max(0, Math.min(1, (x - height / 2) / usable));
            root.dragValue = value;
            root.moved(value);
        }

        onPressed: event => update(event.x)
        onPositionChanged: event => {
            if (pressed)
                update(event.x);
        }
    }

    WheelHandler {
        target: null

        onWheel: event => {
            const delta = event.angleDelta.y;
            if (delta !== 0) {
                const next = root.value + (delta > 0 ? root.wheelStep : -root.wheelStep);
                root.moved(Math.max(0, Math.min(1, next)));
            }
        }
    }
}