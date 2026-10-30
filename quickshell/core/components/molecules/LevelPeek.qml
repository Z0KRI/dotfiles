// MOLÉCULA: un nivel en la isla plegada, como el "sneak peek" de Boring
// Notch: el ícono a la izquierda, la barra al centro y el valor a la derecha.
// Lo usan el volumen y el brillo, que son gemelos.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Item {
    id: root

    property string glyph: ""
    property real value: 0      // de 0 a 1
    property string label: ""

    Icon {
        id: glyphIcon

        anchors.left: parent.left
        anchors.leftMargin: 10
        anchors.verticalCenter: parent.verticalCenter

        width: 18
        icon: root.glyph
        size: 14
        color: Theme.island.fg
    }

    Label {
        id: readout

        anchors.right: parent.right
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter

        width: Math.max(readout.implicitWidth, 40)
        horizontalAlignment: Text.AlignRight

        text: root.label
        color: Theme.island.fg
        font.pixelSize: 12
    }

    Rectangle {
        anchors.left: glyphIcon.right
        anchors.leftMargin: 10
        anchors.right: readout.left
        anchors.rightMargin: 10
        anchors.verticalCenter: parent.verticalCenter

        height: 4
        radius: height / 2
        color: Theme.island.track

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, root.value))
            height: parent.height
            radius: parent.radius
            color: Theme.island.fg

            Behavior on width {
                NumberAnimation {
                    duration: Theme.island.closeDuration
                    easing.type: Easing.OutCubic
                }
            }
        }
    }
}
