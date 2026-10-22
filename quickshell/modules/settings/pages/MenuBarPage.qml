// Ajustes › Barra de menús: cuándo se oculta, en qué escritorios nunca, y
// qué muestra (la app activa y el reloj).

import QtQuick
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.desktop
import qs.domain.time

SettingsPage {
    id: root

    readonly property var hideOptions: [
        { value: "always", label: "Siempre" },
        { value: "fullscreen", label: "Pantalla completa" },
        { value: "never", label: "Nunca" }
    ]

    readonly property string hideNote: {
        if (BarVisibility.mode === "always")
            return "La barra aparece al acercar el mouse al borde de arriba, y no empuja las ventanas.";
        if (BarVisibility.mode === "fullscreen")
            return "Se oculta solo cuando una app está en pantalla completa.";
        return "Siempre visible, también sobre las apps en pantalla completa.";
    }

    SettingsGroup {
        footer: root.hideNote

        SettingsRow {
            title: "Ocultar automáticamente"

            SegmentedControl {
                options: root.hideOptions
                current: BarVisibility.mode
                onSelected: value => BarVisibility.setMode(value)
            }
        }

        SettingsRow {
            title: "Escritorios fijos"
            subtitle: "En estos la barra nunca se oculta."
            enabled: BarVisibility.mode !== "never"

            Row {
                spacing: 4

                Repeater {
                    model: 10

                    ToggleChip {
                        required property int index

                        text: String(index + 1)
                        checked: BarVisibility.isPinnedWorkspace(index + 1)
                        onToggled: BarVisibility.togglePinned(index + 1)
                    }
                }
            }
        }
    }

    SettingsGroup {
        header: "Contenido"

        ToggleRow {
            title: "Mostrar la app activa"
            subtitle: "El nombre de la ventana enfocada, junto al logo de Arch."
            checked: BarVisibility.showActiveApp
            onToggled: BarVisibility.setShowActiveApp(!BarVisibility.showActiveApp)
        }
    }

    SettingsGroup {
        header: "Reloj"

        ToggleRow {
            title: "Mostrar la fecha"
            checked: Clock.showDate
            onToggled: Clock.setShowDate(!Clock.showDate)
        }

        ToggleRow {
            title: "Formato de 24 horas"
            checked: !Clock.twelveHour
            onToggled: Clock.setTwelveHour(!Clock.twelveHour)
        }

        SettingsRow {
            title: "Así se ve"
            value: Clock.label
        }
    }
}
