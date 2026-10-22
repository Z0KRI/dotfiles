// Ajustes › Sonido: volumen y salida, micrófono y entrada.
// Los deslizadores usan las mismas reglas que el Centro de control (Audio y
// Microphone): subir el volumen quita el silencio, nunca pasa de 100 %.

import QtQuick
import QtQuick.Layouts
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.audio

SettingsPage {
    id: root

    SettingsGroup {
        header: "Salida"

        SettingsRow {
            title: "Volumen"

            KnobSlider {
                implicitWidth: 260
                value: Audio.muted ? 0 : Audio.volume
                leadingIcon: Theme.systemIcons.volume.low
                trailingIcon: Theme.systemIcons.volume.high
                onMoved: value => Audio.setVolume(value)
            }

            Label {
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
                text: Audio.muted ? "—" : Audio.percent + "%"
                color: Theme.window.textMuted
                font.pixelSize: Theme.window.fontCaption + 1
            }
        }

        ToggleRow {
            title: "Silenciar"
            checked: Audio.muted
            onToggled: Audio.toggleMuted()
        }
    }

    SettingsGroup {
        header: "Dispositivo de salida"

        Repeater {
            model: Audio.outputs

            SettingsRow {
                id: output

                required property var modelData

                glyph: Theme.systemIcons.device[output.modelData.kind]
                title: output.modelData.label
                clickable: true
                onActivated: Audio.selectOutput(output.modelData.id)

                Icon {
                    visible: output.modelData.selected
                    icon: Theme.systemIcons.check
                    size: 15
                    color: Theme.colors.accent
                }
            }
        }

        SettingsRow {
            visible: Audio.outputs.length === 0
            title: "No hay salidas de audio."
        }
    }

    SettingsGroup {
        header: "Entrada"
        visible: Microphone.available

        SettingsRow {
            title: "Volumen del micrófono"

            KnobSlider {
                implicitWidth: 260
                value: Microphone.shownVolume
                leadingIcon: Theme.systemIcons.micOff
                trailingIcon: Theme.systemIcons.mic
                onMoved: value => Microphone.setVolume(value)
            }

            Label {
                Layout.preferredWidth: 36
                horizontalAlignment: Text.AlignRight
                text: Microphone.muted ? "—" : Math.round(Microphone.volume * 100) + "%"
                color: Theme.window.textMuted
                font.pixelSize: Theme.window.fontCaption + 1
            }
        }

        ToggleRow {
            title: "Silenciar el micrófono"
            checked: Microphone.muted
            onToggled: Microphone.toggleMute()
        }
    }

    SettingsGroup {
        header: "Dispositivo de entrada"
        visible: Microphone.inputs.length > 0

        Repeater {
            model: Microphone.inputs

            SettingsRow {
                id: input

                required property var modelData

                glyph: input.modelData.kind === "mic"
                    ? Theme.systemIcons.mic
                    : Theme.systemIcons.device[input.modelData.kind]
                title: input.modelData.label
                clickable: true
                onActivated: Microphone.selectInput(input.modelData.id)

                Icon {
                    visible: input.modelData.selected
                    icon: Theme.systemIcons.check
                    size: 15
                    color: Theme.colors.accent
                }
            }
        }
    }

    Item {
        visible: Audio.hasSettingsApp
        width: parent.width
        height: advanced.height

        PushButton {
            id: advanced

            anchors.right: parent.right
            text: "Configuración avanzada…"
            onClicked: Audio.openSettings()
        }
    }
}
