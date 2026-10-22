// MOLÉCULA: el deslizador de Ajustes: pista delgada, la parte llena en color
// de acento y una perilla blanca con sombra. Opcional: íconos a los lados,
// textos en los extremos (minLabel/maxLabel) y marcas (ticks).
//
// Mismo patrón que tu LineSlider: mientras arrastras se muestra TU posición
// (dragValue), no la que devuelve el sistema, para que no tiemble.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Item {
    id: root

    property real value: 0
    property string leadingIcon: ""
    property string trailingIcon: ""
    property string minLabel: ""
    property string maxLabel: ""
    property int ticks: 0          // 0 = sin marcas; 5 = cinco marcas
    property real wheelStep: 0.05

    signal moved(real value)
    signal released()

    readonly property int knobSize: 18
    readonly property bool hasLabels: root.minLabel !== "" || root.maxLabel !== ""

    implicitWidth: 240
    implicitHeight: root.hasLabels ? 38 : 22

    property real dragValue: 0
    readonly property real shownValue: mouse.pressed ? root.dragValue : root.value

    function clamp(value) {
        return Math.max(0, Math.min(1, value));
    }

    Icon {
        id: leading

        visible: root.leadingIcon !== ""
        anchors.left: parent.left
        anchors.verticalCenter: rail.verticalCenter
        icon: root.leadingIcon
        size: 13
        color: Theme.window.textMuted
    }

    Icon {
        id: trailing

        visible: root.trailingIcon !== ""
        anchors.right: parent.right
        anchors.verticalCenter: rail.verticalCenter
        icon: root.trailingIcon
        size: 16
        color: Theme.window.textMuted
    }

    // La zona útil. La perilla no se sale: el valor 0 deja su centro a medio
    // diámetro del borde, y el 1 igual del otro lado.
    Item {
        id: rail

        anchors.left: leading.visible ? leading.right : parent.left
        anchors.leftMargin: leading.visible ? 8 : 0
        anchors.right: trailing.visible ? trailing.left : parent.right
        anchors.rightMargin: trailing.visible ? 8 : 0
        anchors.top: parent.top
        height: 22

        readonly property real usable: width - root.knobSize

        Rectangle {
            id: track

            x: root.knobSize / 2
            width: rail.usable
            anchors.verticalCenter: parent.verticalCenter
            height: 4
            radius: 2
            color: Theme.window.track

            Rectangle {
                width: root.shownValue * parent.width
                height: parent.height
                radius: parent.radius
                color: Theme.colors.accent
            }
        }

        Repeater {
            model: root.ticks

            Rectangle {
                required property int index

                x: root.knobSize / 2 + rail.usable * index / Math.max(1, root.ticks - 1) - 1
                anchors.top: track.bottom
                anchors.topMargin: 4
                width: 2
                height: 4
                radius: 1
                color: Theme.window.track
            }
        }

        // Sombra + perilla. La sombra es un círculo gris un poco más abajo:
        // barato, y suficiente a este tamaño.
        Rectangle {
            x: knob.x
            y: knob.y + 1
            width: knob.width
            height: knob.height
            radius: width / 2
            color: Theme.window.shadow
        }

        Rectangle {
            id: knob

            x: root.shownValue * rail.usable
            anchors.verticalCenter: parent.verticalCenter
            width: root.knobSize
            height: root.knobSize
            radius: width / 2
            color: Theme.window.knob
            border.width: 1
            border.color: Theme.window.controlBorder
            scale: mouse.pressed ? 1.08 : 1

            Behavior on x {
                enabled: !mouse.pressed
                NumberAnimation { duration: 160; easing.type: Easing.OutCubic }
            }

            Behavior on scale {
                NumberAnimation { duration: 120 }
            }
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            function seek(x): void {
                const value = root.clamp((x - root.knobSize / 2) / rail.usable);
                root.dragValue = value;
                root.moved(value);
            }

            onPressed: event => seek(event.x)
            onPositionChanged: event => {
                if (pressed)
                    seek(event.x);
            }
            onReleased: root.released()
        }

        WheelHandler {
            target: null

            onWheel: event => {
                const delta = event.angleDelta.y;
                if (delta !== 0)
                    root.moved(root.clamp(root.value + (delta > 0 ? root.wheelStep : -root.wheelStep)));
            }
        }
    }

    Label {
        visible: root.minLabel !== ""
        anchors.left: rail.left
        anchors.bottom: parent.bottom
        text: root.minLabel
        color: Theme.window.textMuted
        font.pixelSize: Theme.window.fontCaption
    }

    Label {
        visible: root.maxLabel !== ""
        anchors.right: rail.right
        anchors.bottom: parent.bottom
        text: root.maxLabel
        color: Theme.window.textMuted
        font.pixelSize: Theme.window.fontCaption
    }
}
