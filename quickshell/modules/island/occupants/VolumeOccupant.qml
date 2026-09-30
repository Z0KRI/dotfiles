// Aparece cuando cambia el volumen y se retira solo.
//
// El detalle del arranque: al conectarse el primer nodo de Pipewire llega un
// cambio que nadie ha pedido, así que la island saldría sola al iniciar sesión.
// De eso se encarga `armed`.

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
    contentHeight: Theme.island.pillHeight

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

    // Anclas y no un Row centrado: los extremos se fijan al borde y la barra
    // se come lo que sobra. Centrar un Row deja toda la holgura de un lado en
    // cuanto su ancho no coincide con lo que se ve.
    view: Component {
        Item {
            anchors.fill: parent

            Label {
                id: glyph

                anchors.left: parent.left
                anchors.leftMargin: Theme.island.pillPadding
                anchors.verticalCenter: parent.verticalCenter

                // Ancho fijo para que la barra no se mueva al cambiar de icono:
                // el del silencio y el del volumen alto no miden lo mismo.
                width: 18
                horizontalAlignment: Text.AlignHCenter

                text: Volume.icon
                color: Theme.island.fg
                font.family: Theme.font.mono

                // En píxeles, SIEMPRE. El tamaño por defecto de Qt está en
                // puntos y cada monitor lo convierte con sus propios DPI.
                font.pixelSize: 15
            }

            Label {
                id: readout

                anchors.right: parent.right
                anchors.rightMargin: Theme.island.pillPadding
                anchors.verticalCenter: parent.verticalCenter

                // Lo que mida su texto, pero nunca menos de 40: así la barra
                // no da un respingo al pasar de "99%" a "100%".
                width: Math.max(readout.implicitWidth, 40)
                horizontalAlignment: Text.AlignRight

                text: Volume.label
                color: Theme.island.fg
                font.pixelSize: 13
            }

            Rectangle {
                anchors.left: glyph.right
                anchors.leftMargin: 12
                anchors.right: readout.left
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter

                height: 5
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
                            duration: Theme.motion.duration
                            easing.type: Easing.OutCubic
                        }
                    }
                }
            }
        }
    }
}