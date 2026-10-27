pragma ComponentBehavior: Bound

// (Bound: los delegados de los Repeater pueden leer los id de afuera,
// como `root`, y qmllint lo sabe. A cambio, lo de cada delegado se pide
// con su id: `fila.modelData`, no `modelData` a secas desde un hijo.)

// Ajustes › Pantallas: acomodar tus monitores y, del que elijas, tamaño,
// resolución, frecuencia, rotación, VRR, duplicar y encenderlo o apagarlo.
// Abajo, brillo y luz nocturna (hyprsunset).
//
// La página solo pinta y avisa. Las reglas (qué escala es válida, a dónde se
// pega un monitor, la prueba de 15 s) son de Displays; la hoja de "¿Conservar
// esta configuración?" la pone la ventana de Ajustes.

import QtQuick
import QtQuick.Layouts
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.desktop

SettingsPage {
    id: root

    // El monitor que estás editando. Al abrir, el que tiene el ratón.
    property string selectedName: ""
    readonly property var monitor: Displays.find(root.selectedName)
                                   ?? Displays.monitors.find(m => m.focused)
                                   ?? Displays.monitors[0]
                                   ?? null
    readonly property bool usable: root.monitor !== null && !root.monitor.disabled

    property bool allResolutions: false

    readonly property var rotations: [
        { value: 0, label: "Normal" },
        { value: 1, label: "90°" },
        { value: 2, label: "180°" },
        { value: 3, label: "270°" }
    ]

    readonly property var vrrModes: [
        { value: 0, label: "No" },
        { value: 1, label: "Siempre" },
        { value: 2, label: "Pantalla completa" }
    ]

    Component.onCompleted: Displays.refresh()

    // ── Organizar ────────────────────────────────────────────
    SettingsGroup {
        visible: Displays.monitors.length > 0
        footer: Displays.arranged.length > 1
            ? "Arrastra las pantallas para acomodarlas como están en tu escritorio. Al soltar, se pegan a la de al lado."
            : ""

        DisplayArrangement {
            width: parent.width
            height: 200
            monitors: Displays.arranged.map(m => ({
                name: m.name,
                x: m.x,
                y: m.y,
                width: m.logicalWidth,
                height: m.logicalHeight
            }))
            selected: root.monitor?.name ?? ""
            movable: Displays.arranged.length > 1 && !Displays.confirming
            onPicked: name => root.selectedName = name
            onDropped: (name, x, y) => Displays.move(name, x, y)
        }

        // Para llegar también a los apagados, que no se dibujan arriba.
        SettingsRow {
            visible: Displays.monitors.length > 1
            title: "Pantalla"

            Row {
                spacing: 4

                Repeater {
                    model: Displays.monitors

                    ToggleChip {
                        required property var modelData

                        text: modelData.name
                        checked: modelData.name === root.monitor?.name
                        opacity: modelData.disabled ? 0.6 : 1
                        onToggled: root.selectedName = modelData.name
                    }
                }
            }
        }
    }

    SettingsGroup {
        visible: !Displays.loaded

        SettingsRow {
            title: "Leyendo tus monitores…"
        }
    }

    // ── El monitor elegido ───────────────────────────────────
    SettingsHero {
        visible: root.monitor !== null

        icon: root.usable ? Theme.systemIcons.monitor : Theme.systemIcons.monitorOff
        tint: root.usable ? "#0a84ff" : "#8e8e93"
        title: root.monitor?.title ?? ""
        description: {
            const m = root.monitor;
            if (!m)
                return "";
            if (m.disabled)
                return m.name + " · apagada";
            if (m.mirror !== "")
                return m.name + " · duplica " + m.mirror;
            return m.name + " · " + m.label;
        }

        // El último monitor encendido no se puede apagar: sin interruptor.
        showSwitch: root.monitor !== null && Displays.canDisable(root.monitor.name)
        checked: root.usable
        onToggled: Displays.setEnabled(root.monitor.name, root.monitor.disabled)
    }

    Label {
        visible: Displays.lastError !== ""
        width: parent.width
        wrapMode: Text.WordWrap
        text: "Hyprland no aceptó el cambio: " + Displays.lastError
        color: Theme.colors.error
        font.pixelSize: Theme.window.fontCaption
    }

    // ── Tamaño (escala) ──────────────────────────────────────
    SettingsGroup {
        visible: root.usable && root.monitor.scales.length > 1
        header: "Tamaño"
        footer: root.usable
            ? "Se ve como " + root.monitor.logicalWidth + " × " + root.monitor.logicalHeight
              + ". La pantalla sigue en " + root.monitor.width + " × " + root.monitor.height
              + "; cambia qué tan grande se dibuja todo."
            : ""

        Item {
            width: parent.width
            height: options.height + 46

            Row {
                id: options

                anchors.horizontalCenter: parent.horizontalCenter
                y: 14
                spacing: 10

                Repeater {
                    model: root.usable ? root.monitor.scales : []

                    ScaleOption {
                        required property var modelData
                        required property int index

                        readonly property int count: root.monitor.scales.length

                        // La primera es la de escala mayor: texto más grande.
                        weight: count > 1 ? 1 - index / (count - 1) : 0.5
                        text: modelData.width + " × " + modelData.height
                        selected: Math.abs(modelData.scale - root.monitor.scale) < 0.01
                        onActivated: Displays.setScale(root.monitor.name, modelData.scale)
                    }
                }
            }

            Label {
                anchors.left: options.left
                anchors.top: options.bottom
                anchors.topMargin: 6
                text: "Texto más grande"
                color: Theme.window.textMuted
                font.pixelSize: Theme.window.fontCaption
            }

            Label {
                anchors.right: options.right
                anchors.top: options.bottom
                anchors.topMargin: 6
                text: "Más espacio"
                color: Theme.window.textMuted
                font.pixelSize: Theme.window.fontCaption
            }
        }
    }

    // ── Modo, rotación, VRR y duplicar ───────────────────────
    SettingsGroup {
        visible: root.usable

        SettingsRow {
            glyph: Theme.systemIcons.resolution
            title: "Resolución"
            value: root.usable ? root.monitor.width + " × " + root.monitor.height : ""
        }

        ToggleRow {
            title: "Mostrar todas las resoluciones"
            checked: root.allResolutions
            onToggled: root.allResolutions = !root.allResolutions
        }

        Repeater {
            model: root.usable && root.allResolutions ? root.monitor.resolutions : []

            SettingsRow {
                id: resolution

                required property var modelData

                readonly property bool current: root.monitor.width === modelData.width
                                                && root.monitor.height === modelData.height

                title: modelData.width + " × " + modelData.height
                clickable: !resolution.current
                onActivated: Displays.setResolution(root.monitor.name, modelData.width, modelData.height)

                Icon {
                    visible: resolution.current
                    icon: Theme.systemIcons.check
                    size: 15
                    color: Theme.colors.accent
                }
            }
        }

        SettingsRow {
            title: "Frecuencia de actualización"

            Flow {
                Layout.preferredWidth: 300
                width: 300
                spacing: 4
                layoutDirection: Qt.RightToLeft

                Repeater {
                    model: root.usable ? root.monitor.rates : []

                    ToggleChip {
                        required property var modelData

                        text: modelData.label
                        checked: Math.abs(modelData.rate - root.monitor.refreshRate) < 0.05
                        onToggled: Displays.setRate(root.monitor.name, modelData.rate)
                    }
                }
            }
        }

        SettingsRow {
            glyph: Theme.systemIcons.rotate
            title: "Rotación"

            SegmentedControl {
                options: root.rotations
                current: root.monitor?.transform ?? 0
                onSelected: value => Displays.setTransform(root.monitor.name, value)
            }
        }

        SettingsRow {
            glyph: Theme.systemIcons.vrr
            title: "Frecuencia variable"
            subtitle: "VRR: evita cortes en juegos y videos, si tu monitor lo soporta."

            SegmentedControl {
                options: root.vrrModes
                current: root.monitor?.vrr ?? 0
                onSelected: value => Displays.setVrr(root.monitor.name, value)
            }
        }

        SettingsRow {
            visible: Displays.monitors.length > 1
            glyph: Theme.systemIcons.mirror
            title: "Duplicar"
            subtitle: "Muestra lo mismo que otra pantalla."

            Row {
                spacing: 4

                ToggleChip {
                    text: "No"
                    checked: root.monitor?.mirror === ""
                    onToggled: Displays.setMirror(root.monitor.name, "")
                }

                Repeater {
                    model: Displays.active.filter(m => m.name !== root.monitor?.name && m.mirror === "")

                    ToggleChip {
                        required property var modelData

                        text: modelData.name
                        checked: root.monitor?.mirror === modelData.name
                        onToggled: Displays.setMirror(root.monitor.name, modelData.name)
                    }
                }
            }
        }
    }

    // ── Brillo y luz nocturna ────────────────────────────────
    SettingsGroup {
        header: "Brillo"
        footer: "Se ajusta por software con la gamma de hyprsunset, en todas las pantallas a "
                + "la vez, y nunca baja de 20 % para que no te quedes a oscuras."

        SettingsRow {
            title: "Brillo"

            KnobSlider {
                implicitWidth: 300
                value: Brightness.value
                leadingIcon: Theme.systemIcons.sunDim
                trailingIcon: Theme.systemIcons.sun
                onMoved: value => Brightness.setValue(value)
            }
        }
    }

    SettingsGroup {
        header: "Luz nocturna"
        footer: "Colores más cálidos para cansar menos la vista de noche."

        ToggleRow {
            icon: Theme.systemIcons.warmth
            tint: "#ff9f0a"
            title: "Luz nocturna"
            checked: NightLight.enabled
            onToggled: NightLight.toggle()
        }

        SettingsRow {
            title: "Temperatura"
            subtitle: NightLight.temperature + " K"
            enabled: NightLight.enabled

            KnobSlider {
                implicitWidth: 300
                value: NightLight.warmth
                minLabel: "Menos cálida"
                maxLabel: "Más cálida"
                onMoved: value => NightLight.setWarmth(value)
            }
        }
    }

    // ── Restablecer ──────────────────────────────────────────
    SettingsGroup {
        footer: "Lo que conservas aquí se guarda en hypr/hosts/displays.lua, que se carga "
                + "después del archivo de esta máquina. Ese archivo no se sube al repo."

        SettingsRow {
            glyph: Theme.systemIcons.history
            title: "Volver a la configuración de la máquina"
            subtitle: "Borra lo guardado en Ajustes y usa lo de hypr/hosts/<equipo>.lua."

            PushButton {
                text: "Restablecer"
                destructive: true
                enabled: !Displays.confirming
                onClicked: Displays.reset()
            }
        }
    }
}
