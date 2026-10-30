// Ajustes › Teclado: los teclados que tengas conectados, de cualquier marca,
// con lo de Ajustes › Teclado de macOS que tiene sentido en Linux:
//
//   - Tus teclados: cuáles hay, por dónde y su batería (los Bluetooth).
//   - Distribución: cada teclado puede tener la suya. Con varios, eliges en
//     la lista de cuál estás hablando.
//   - Teclado Apple: la tecla fn, ⌘ y ⌥, las ° y <, y qué hace su fila de
//     arriba. Solo aparece con un teclado Apple conectado: al Dell o al ROG
//     no les cambia nada.
//
// Las reglas viven en domain/keyboard (Keyboards y AppleKeyboard).

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.keyboard
import qs.domain.settings

SettingsPage {
    id: root

    // /sys no avisa: se mira cada vez que abres la página.
    Component.onCompleted: {
        Keyboards.refresh();
        AppleKeyboard.refresh();
    }

    // El teclado del que habla la sección de Distribución. Si el elegido se
    // desconecta, el primero.
    property string selectedId: ""
    readonly property var selected: Keyboards.list.find(k => k.id === root.selectedId)
                                    ?? Keyboards.list[0] ?? null
    readonly property bool several: Keyboards.list.length > 1

    readonly property bool canChangeApple: AppleKeyboard.driverLoaded && !AppleKeyboard.applying

    readonly property var isoOptions: [
        { value: "auto", label: "Automático" },
        { value: "normal", label: "Normal" },
        { value: "swapped", label: "Cambiadas" }
    ]

    function describe(keyboard): string {
        let text = Keyboards.busLabel(keyboard);
        if (keyboard.apple)
            text += " · Apple";
        if (keyboard.battery >= 0)
            text += " · " + Math.round(keyboard.battery * 100) + "%" + (keyboard.charging ? " · cargando" : "");
        return text;
    }

    SettingsHero {
        icon: Theme.systemIcons.device.keyboard
        tint: "#8e8e93"
        title: "Teclado"
        description: {
            const count = Keyboards.list.length;
            if (count === 0)
                return "Conecta un teclado, por cable o Bluetooth, para ver aquí sus opciones.";
            if (count === 1)
                return "«" + Keyboards.list[0].name + "» conectado.";
            return count + " teclados conectados.";
        }
    }

    // ── tus teclados ──────────────────────────────────────────────
    SettingsGroup {
        header: "Tus teclados"
        footer: root.several ? "Elige uno para cambiar su distribución." : ""

        Repeater {
            model: Keyboards.list

            SettingsRow {
                id: keyboardRow

                required property var modelData

                readonly property bool low: keyboardRow.modelData.battery >= 0
                                            && !keyboardRow.modelData.charging
                                            && keyboardRow.modelData.battery <= 0.2

                glyph: Theme.systemIcons.device.keyboard
                title: keyboardRow.modelData.name
                subtitle: root.describe(keyboardRow.modelData)
                value: Keyboards.labelOf(keyboardRow.modelData.layout)
                clickable: root.several
                onActivated: root.selectedId = keyboardRow.modelData.id

                Icon {
                    visible: keyboardRow.modelData.battery >= 0
                    icon: Theme.batteryIcon(keyboardRow.modelData.battery, keyboardRow.modelData.charging)
                    size: 16
                    color: keyboardRow.low ? Theme.colors.error : Theme.window.textMuted
                }

                Icon {
                    visible: root.several && root.selected !== null
                             && root.selected.id === keyboardRow.modelData.id
                    icon: Theme.systemIcons.check
                    size: 15
                    color: Theme.colors.accent
                }
            }
        }

        SettingsRow {
            visible: !Keyboards.connected
            glyph: Theme.systemIcons.bluetooth.on
            title: "No hay teclados conectados."
            subtitle: "Para uno Bluetooth: Bluetooth › Dispositivos cercanos › Conectar."
            navigates: true
            onActivated: SettingsControl.go("bluetooth")
        }
    }

    // ── distribución ──────────────────────────────────────────────
    SettingsGroup {
        visible: root.selected !== null
        header: root.several && root.selected ? "Distribución de «" + root.selected.name + "»" : "Distribución"
        footer: "Solo para este teclado: los demás siguen con la del equipo. Se guarda en "
                + "hypr/hosts/keyboard.lua, solo en esta computadora."

        Repeater {
            model: Keyboards.optionsFor(root.selected)

            SettingsRow {
                id: layoutRow

                required property var modelData

                glyph: layoutRow.modelData.id === "system" ? Theme.systemIcons.monitor : Theme.systemIcons.languages
                title: layoutRow.modelData.label
                subtitle: layoutRow.modelData.detail
                clickable: true
                onActivated: Keyboards.setLayout(root.selected.id, layoutRow.modelData.id)

                Icon {
                    visible: root.selected !== null && root.selected.layout === layoutRow.modelData.id
                    icon: Theme.systemIcons.check
                    size: 15
                    color: Theme.colors.accent
                }
            }
        }
    }

    // ── teclado Apple ─────────────────────────────────────────────
    SettingsGroup {
        visible: AppleKeyboard.connected
        header: "Teclado Apple"
        footer: AppleKeyboard.lastError !== ""
            ? AppleKeyboard.lastError
            : "Las teclas de función y ° < son opciones del sistema: piden tu contraseña. "
              + "A los teclados de otras marcas no les cambia nada"
              // El driver no distingue: "Cambiadas" también vale para los
              // genéricos que se hacen pasar por Apple.
              + (AppleKeyboard.lookalikes.length > 0
                 ? ", salvo «Cambiadas»: también vale para «" + AppleKeyboard.lookalikes[0].name
                   + "», que usa el driver de Apple."
                 : ".")

        ToggleRow {
            enabled: root.canChangeApple
            glyph: Theme.systemIcons.functionKeys
            title: "Usar F1, F2, etc. como teclas de función estándar"
            subtitle: AppleKeyboard.functionKeys
                ? "La fila de arriba manda F1–F12. Brillo, música y volumen salen con fn."
                : "La fila de arriba hace brillo, música y volumen, como en macOS. F1–F12 salen con fn."
            checked: AppleKeyboard.functionKeys
            onToggled: AppleKeyboard.setFunctionKeys(!AppleKeyboard.functionKeys)
        }

        ToggleRow {
            enabled: !AppleKeyboard.applying
            glyph: Theme.systemIcons.command
            title: "Intercambiar ⌘ Comando y ⌥ Opción"
            subtitle: "Solo en el teclado Apple: la ⌥ izquierda hace de SUPER y la ⌘ de Alt, como en "
                      + "un teclado de PC, y tus atajos caen en el mismo lugar con cualquier teclado. "
                      + "La ⌥ derecha sigue siendo AltGr."
            checked: AppleKeyboard.swapCommandOption
            onToggled: AppleKeyboard.setSwapCommandOption(!AppleKeyboard.swapCommandOption)
        }

        SettingsRow {
            visible: AppleKeyboard.hasIsoOption
            enabled: root.canChangeApple
            glyph: Theme.systemIcons.swapKeys
            title: "Teclas ° y <"
            subtitle: "Si al escribir < sale ° (o al revés), elige Cambiadas."

            SegmentedControl {
                options: root.isoOptions
                current: AppleKeyboard.isoMode
                onSelected: value => AppleKeyboard.setIsoMode(value)
            }
        }
    }

    // ── la fila de arriba del teclado Apple ───────────────────────
    //
    // Del Magic Keyboard sin lupa (2015–2020); el de 2021 trae la lupa en F4,
    // que abre la búsqueda general. Solo con un teclado Apple: en los demás,
    // F1–F12 siguen siendo F1–F12.
    SettingsGroup {
        visible: AppleKeyboard.connected
        header: "La fila de arriba del teclado Apple"
        footer: (AppleKeyboard.functionKeys ? "Con F1–F12 como estándar, esto sale con fn. "
                                            : "Con fn mandan F1–F12. ")
                + "En los otros teclados, F1–F12 siguen siendo F1–F12; si traen teclas de "
                + "música o volumen, también sirven."

        SettingsRow {
            glyph: Theme.systemIcons.sun
            title: "F1 · F2"
            value: "Brillo"
        }

        SettingsRow {
            glyph: Theme.systemIcons.launchpad
            title: "F4 · Launchpad"
            value: "Spotlight › Aplicaciones"
        }

        SettingsRow {
            glyph: Theme.systemIcons.music
            title: "F7 · F8 · F9"
            value: "Anterior · Reproducir · Siguiente"
        }

        SettingsRow {
            glyph: Theme.systemIcons.volume.high
            title: "F10 · F11 · F12"
            value: "Silencio · Bajar · Subir"
        }
    }
}
