// Aparece cuando cambia el volumen y se retira solo. Es el "sneak peek" de
// Boring Notch: el notch cerrado se ensancha, sin cambiar de alto.

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.domain.status

IslandOccupant {
    id: root

    name: "volume"
    priority: 60

    ephemeral: true
    timeout: 1800

    contentWidth: 250
    contentHeight: Theme.island.closedHeight

    // No reaccionar al primer valor que publica Pipewire al arrancar.
    property bool armed: false

    Timer {
        interval: 800
        running: true
        onTriggered: root.armed = true
    }

    Connections {
        target: Volume

        function onChanged() {
            if (root.armed)
                root.poke();
        }
    }

    view: Component {
        Item {
            anchors.fill: parent

            Label {
                id: glyph

                anchors.left: parent.left
                anchors.leftMargin: 10
                anchors.verticalCenter: parent.verticalCenter

                width: 18
                horizontalAlignment: Text.AlignHCenter

                text: Volume.icon
                color: Theme.island.fg
                font.family: Theme.font.mono
                font.pixelSize: 14
            }

            Label {
                id: readout

                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter

                width: Math.max(readout.implicitWidth, 40)
                horizontalAlignment: Text.AlignRight

                text: Volume.label
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
                    width: parent.width * (Volume.muted
                                           ? 0
                                           : Math.min(1, Volume.percent / 100))
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