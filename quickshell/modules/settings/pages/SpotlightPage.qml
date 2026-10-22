// Ajustes › Spotlight: el historial con el que se ordenan las apps, y los
// atajos (solo informativos: viven en tu config de Hyprland).

import QtQuick
import qs.core.theme
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.launcher

SettingsPage {
    id: root

    SettingsHero {
        icon: Theme.systemIcons.search
        tint: "#8e8e93"
        title: "Spotlight"
        description: "Busca y abre tus apps desde el teclado."
    }

    SettingsGroup {
        header: "Historial"
        footer: "Spotlight cuenta cuántas veces abres cada app para ponerte primero las "
                + "que más usas. Se guarda solo en este equipo."

        ToggleRow {
            title: "Recordar las apps que abro"
            checked: LaunchHistory.enabled
            onToggled: LaunchHistory.setEnabled(!LaunchHistory.enabled)
        }

        SettingsRow {
            glyph: Theme.systemIcons.history
            title: "Apps en el historial"
            value: String(LaunchHistory.appCount)

            PushButton {
                text: "Borrar historial"
                destructive: true
                enabled: LaunchHistory.appCount > 0
                onClicked: LaunchHistory.clear()
            }
        }
    }

    SettingsGroup {
        header: "Atajos"
        footer: "Se cambian en hypr/theme/config/keybindings.lua."

        SettingsRow {
            title: "Abrir Spotlight"
            value: "Super + Espacio"
        }

        SettingsRow {
            title: "Abrir Ajustes"
            value: "Super + ,"
        }
    }
}
