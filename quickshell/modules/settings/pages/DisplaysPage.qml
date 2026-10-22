// Ajustes › Pantallas: brillo, luz nocturna y tus monitores.
// Brillo y luz nocturna van por hyprsunset: si no está corriendo, los
// deslizadores se mueven pero la pantalla no cambia (la nota lo dice).

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.desktop

SettingsPage {
    id: root

    SettingsGroup {
        footer: "Se ajusta por software con la gamma de hyprsunset, y nunca baja de 20 % "
                + "para que no te quedes a oscuras."

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

    SettingsGroup {
        header: "Monitores"
        footer: "La resolución y la posición se cambian en tu config de Hyprland "
                + "(hypr/hosts/<equipo>.lua)."

        Repeater {
            model: Displays.monitors

            SettingsRow {
                id: monitor

                required property var modelData

                glyph: Theme.systemIcons.monitor
                title: monitor.modelData.title
                subtitle: monitor.modelData.detail
                value: monitor.modelData.focused ? "En uso" : ""
            }
        }
    }
}
