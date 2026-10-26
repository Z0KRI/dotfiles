// Ajustes › AirPods: lo que macOS enseña al tocar tus AirPods en Ajustes.
// Batería de cada pieza, control de ruido y detección de conversación.
//
// Todo eso sale de LibrePods. Sin él, o sin los AirPods conectados, la página
// dice qué falta en vez de quedarse vacía. Lo que LibrePods tiene y aquí no
// (renombrarlos, volumen personalizado, habilitar el modo Desactivado,
// controles del tallo) está en su propia ventana: "Abrir LibrePods…".
//
// El modo Apple (tu PC presentándose como un aparato de Apple) es un ajuste
// del sistema: aquí solo se enseña. Se cambia con ./install.sh --airpods,
// que pregunta, guarda una copia y reinicia Bluetooth.

import QtQuick
import qs.core.theme
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.airpods
import qs.domain.bluetooth
import qs.domain.settings

SettingsPage {
    id: root

    // El modo Apple se mira cada vez que abres la página: pudiste cambiarlo
    // con el install mientras la shell corría.
    Component.onCompleted: AirPods.refreshAppleMode()

    readonly property bool ready: AirPods.connected && AirPods.controllable

    readonly property var modeNotes: ({
        off: "Sin cancelación ni transparencia.",
        transparency: "Deja pasar el sonido de tu alrededor, para oír lo que pasa.",
        adaptive: "Mezcla cancelación y transparencia según el ruido que haya.",
        anc: "Bloquea el ruido de tu alrededor."
    })

    SettingsHero {
        icon: Theme.systemIcons.device.headphones
        tint: "#636366"
        title: AirPods.name
        description: {
            if (!AirPods.connected)
                return "Conéctalos en Bluetooth para ver aquí su batería y el control de ruido.";
            if (!AirPods.installed)
                return "Conectados. Para el control de ruido y la batería hace falta LibrePods.";
            if (!AirPods.controllable)
                return "Conectados. LibrePods no está abierto.";
            return "Conectados.";
        }
    }

    // ── batería ───────────────────────────────────────────────────
    SettingsGroup {
        visible: root.ready && AirPods.pieces.length > 0
        header: "Batería"

        Item {
            width: parent.width
            height: gauges.height + 24

            Row {
                id: gauges

                anchors.centerIn: parent
                spacing: 36

                Repeater {
                    model: AirPods.pieces

                    BatteryGauge {
                        required property var modelData

                        label: modelData.label
                        level: modelData.level
                        charging: modelData.charging
                        contentColor: Theme.window.text
                        mutedColor: Theme.window.textMuted
                    }
                }
            }
        }
    }

    // ── control de ruido ──────────────────────────────────────────
    SettingsGroup {
        visible: root.ready && (AirPods.modes.length > 0 || AirPods.hasConversation)
        header: "Control de ruido"
        footer: root.modeNotes[AirPods.mode] ?? ""

        SettingsRow {
            visible: AirPods.modes.length > 0
            title: "Modo"

            SegmentedControl {
                options: AirPods.modes.map(mode => ({ value: mode.id, label: mode.short }))
                current: AirPods.mode
                onSelected: value => AirPods.setMode(value)
            }
        }

        ToggleRow {
            visible: AirPods.hasConversation
            glyph: Theme.systemIcons.airpods.conversation
            title: "Detección de conversación"
            subtitle: "Baja el volumen y deja pasar las voces cuando empiezas a hablar."
            checked: AirPods.conversation
            onToggled: AirPods.toggleConversation()
        }
    }

    // Recién conectados: LibrePods todavía está hablando con ellos.
    SettingsGroup {
        visible: root.ready && AirPods.modes.length === 0 && AirPods.pieces.length === 0

        SettingsRow {
            glyph: Theme.systemIcons.scanning
            title: "Esperando a que LibrePods lea tus AirPods…"
        }
    }

    // ── LibrePods ─────────────────────────────────────────────────
    SettingsGroup {
        header: "LibrePods"
        footer: AirPods.installed
            ? "Renombrarlos, el volumen personalizado, el modo Desactivado y los controles del "
              + "tallo están en la ventana de LibrePods. El modo Apple se cambia con "
              + "«./install.sh --airpods»."
            : "Instálalo con «./install.sh --airpods» desde tus dotfiles y reinicia la shell."

        SettingsRow {
            glyph: Theme.systemIcons.info
            title: "Estado"
            value: {
                if (!AirPods.installed)
                    return "No instalado";
                return AirPods.controllable ? "Abierto" : "Cerrado";
            }

            PushButton {
                visible: AirPods.installed
                text: AirPods.controllable ? "Abrir LibrePods…" : "Iniciar"
                onClicked: AirPods.openApp()
            }
        }

        SettingsRow {
            glyph: Theme.systemIcons.airpods.appleMode
            title: "Modo Apple"
            subtitle: "Tu PC se presenta como un aparato de Apple y los AirPods le dan lo que "
                      + "solo le dan a Apple, como conectarse a la vez a tu iPhone y a la PC."
            value: AirPods.appleMode ? "Activado" : "Desactivado"
        }
    }

    // ── acciones ──────────────────────────────────────────────────
    Item {
        width: parent.width
        height: actions.height

        Row {
            id: actions

            anchors.right: parent.right
            spacing: 8

            PushButton {
                visible: !AirPods.connected
                text: "Ir a Bluetooth…"
                onClicked: SettingsControl.go("bluetooth")
            }

            PushButton {
                visible: AirPods.connected
                text: "Desconectar"
                onClicked: BluetoothControl.toggleDevice(AirPods.address)
            }
        }
    }
}
