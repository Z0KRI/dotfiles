// MOLÉCULA: deslizador delgado estilo Tahoe, con un ícono a cada lado y,
// si se pide, un botón redondo al final (ej. elegir la salida de audio).

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Item {
    id: root

    property real value: 0
    property string leadingIcon: ""
    property string trailingIcon: ""
    property string actionIcon: ""   // "" = sin botón al final
    property real wheelStep: 0.05

    signal moved(real value)
    signal actionClicked()

    implicitWidth: 280
    implicitHeight: 24

    // Mientras arrastras, se muestra tu posición, no la del sistema.
    property real dragValue: 0
    readonly property real shownValue: mouse.pressed ? root.dragValue : root.value

    function clamp(value) {
        return Math.max(0, Math.min(1, value));
    }

    Icon {
        id: leading

        visible: root.leadingIcon !== ""
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        icon: root.leadingIcon
        size: 13
        color: Theme.glass.content
    }

    // Botón redondo al final.
    Rectangle {
        id: action

        visible: root.actionIcon !== ""
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        width: root.height
        height: root.height
        radius: height / 2
        color: actionHover.hovered ? Theme.glass.tileHover : Theme.glass.control

        Behavior on color {
            ColorAnimation { duration: 120 }
        }

        Icon {
            anchors.centerIn: parent
            icon: root.actionIcon
            size: 13
            color: Theme.glass.content
        }

        HoverHandler {
            id: actionHover
            cursorShape: Qt.PointingHandCursor
        }

        TapHandler {
            onTapped: root.actionClicked()
        }
    }

    Icon {
        id: trailing

        visible: root.trailingIcon !== ""
        anchors.right: action.visible ? action.left : parent.right
        anchors.rightMargin: action.visible ? 10 : 0
        anchors.verticalCenter: parent.verticalCenter
        icon: root.trailingIcon
        size: 17
        color: Theme.glass.content
    }

    // Zona de la pista; también es la que recibe el mouse.
    Item {
        anchors.left: leading.visible ? leading.right : parent.left
        anchors.leftMargin: leading.visible ? 10 : 0
        anchors.right: trailing.visible ? trailing.left : (action.visible ? action.left : parent.right)
        anchors.rightMargin: (trailing.visible || action.visible) ? 10 : 0
        anchors.top: parent.top
        anchors.bottom: parent.bottom

        Rectangle {
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width
            // Al tocarla engrosa un poco, como en macOS.
            height: mouse.pressed ? 8 : 5
            radius: height / 2
            color: Theme.glass.track

            Behavior on height {
                NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
            }

            Rectangle {
                height: parent.height
                width: root.shownValue * parent.width
                radius: height / 2
                color: Theme.glass.content

                // Anima los cambios que llegan del sistema, no los de tu mano.
                Behavior on width {
                    enabled: !mouse.pressed
                    NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
                }
            }
        }

        MouseArea {
            id: mouse

            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            function seek(x): void {
                const value = root.clamp(x / width);
                root.dragValue = value;
                root.moved(value);
            }

            onPressed: event => seek(event.x)
            onPositionChanged: event => {
                if (pressed)
                    seek(event.x);
            }
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
}