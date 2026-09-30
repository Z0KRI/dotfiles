// Menú de sonido, estilo macOS Tahoe: volumen y salida de audio.

import QtQuick
import Quickshell
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.templates
import qs.domain.audio

DropdownWindow {
    id: root

    required property Item anchorItem
    anchor.item: root.anchorItem

    alignRight: true
    padding: 12
    menuWidth: 280

    // Encabezado: "Sonido" y el volumen actual.
    Item {
        width: parent.width
        height: title.implicitHeight + 10

        Label {
            id: title
            text: "Sonido"
            font.weight: Font.Bold
        }

        Label {
            anchors.right: parent.right
            anchors.baseline: title.baseline
            text: Audio.muted ? "Silencio" : Audio.percent + "%"
            opacity: 0.6
        }
    }

    CapsuleSlider {
        width: parent.width
        value: Audio.muted ? 0 : Audio.volume
        icon: Theme.icons.volume[Audio.level]
        onMoved: value => Audio.setVolume(value)
    }

    Item { width: 1; height: 12 }

    Label {
        text: "Salida"
        opacity: 0.6
        font.pixelSize: 11
        font.weight: Font.DemiBold
        bottomPadding: 4
    }

    Repeater {
        model: Audio.outputs

        ChoiceRow {
            required property var modelData

            icon: Theme.systemIcons.device[modelData.kind]
            text: modelData.label
            selected: modelData.selected
            onTriggered: Audio.selectOutput(modelData.id)
        }
    }

    Separator {
        visible: Audio.hasSettingsApp
    }

    MenuItem {
        visible: Audio.hasSettingsApp
        text: "Configuración de sonido…"
        onTriggered: root.run(() => Audio.openSettings())
    }
}