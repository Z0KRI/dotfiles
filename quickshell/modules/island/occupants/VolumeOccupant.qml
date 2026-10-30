// Aparece cuando cambia el volumen y se retira solo. Es el "sneak peek" de
// Boring Notch: el notch cerrado se ensancha, sin cambiar de alto. El brillo
// es su gemelo: los dos usan LevelPeek.

import QtQuick
import qs.core.theme
import qs.core.components.molecules
import qs.domain.audio

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
        target: Audio

        function onChanged() {
            if (root.armed)
                root.poke();
        }
    }

    view: Component {
        LevelPeek {
            anchors.fill: parent
            glyph: Theme.systemIcons.volume[Audio.level]
            value: Audio.muted ? 0 : Audio.percent / 100
            label: Audio.label
        }
    }
}
