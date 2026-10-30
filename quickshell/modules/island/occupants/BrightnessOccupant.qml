// Aparece al tocar las teclas de brillo (F1 y F2 del teclado Mac) y se
// retira solo. Es el gemelo del volumen: mismo tamaño, misma barra
// (LevelPeek), otro ícono. El deslizador del Centro de control no lo llama:
// ahí ya ves el nivel.

import QtQuick
import qs.core.theme
import qs.core.components.molecules
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
        LevelPeek {
            anchors.fill: parent
            glyph: Brightness.value < 0.5 ? Theme.systemIcons.sunDim : Theme.systemIcons.sun
            value: Brightness.value
            label: Brightness.percent + "%"
        }
    }
}
