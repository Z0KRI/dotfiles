// Aparece al tocar las teclas de brillo (F1 y F2 del teclado Mac) y se
// retira solo. Es el gemelo del volumen: mismo tamaño, misma barra, otro
// ícono. El deslizador del Centro de control no lo llama: ahí ya ves el nivel.

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.domain.desktop

IslandOccupant {
    id: root

    name: "brightness"
    priority: 60

    ephemeral: true
    timeout: 1800

    contentWidth: 250
    contentHeight: Theme.island.closedHeight

    Connections {
        target: Brightness

        function onStepped() {
            root.poke();
        }
    }

    view: Component {
        Item {
            anchors.fill: parent

            Icon {
                id: glyph

                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter

                width: 18
                icon: Brightness.value < 0.5 ? Theme.systemIcons.sunDim : Theme.systemIcons.sun
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

                text: Brightness.percent + "%"
                color: Theme.island.fg
                font.pixelSize: 12
            }

            Rectangle {
                anchors.left: glyph.right
                anchors.leftMargin: 10
                anchors.right: readout.left
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter

                height: 4
                radius: height / 2
                color: Theme.island.track

                Rectangle {
                    width: parent.width * Brightness.value
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
    }
}
