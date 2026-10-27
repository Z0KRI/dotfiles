// Ajustes › Spotlight: qué busca la búsqueda general, con qué buscador va a
// la web, qué hace el portapapeles al elegir, el historial con el que se
// ordenan las apps, y los atajos (solo informativos: viven en tu config de
// Hyprland y en el propio panel).

import QtQuick
import qs.core.theme
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.launcher

SettingsPage {
    id: root

    readonly property var engineOptions: WebSearch.engines.map(engine => ({
        value: engine.id, label: engine.label
    }))

    SettingsHero {
        icon: Theme.systemIcons.search
        tint: "#8e8e93"
        title: "Spotlight"
        description: "Busca apps, archivos, tu portapapeles y la web desde el teclado."
    }

    SettingsGroup {
        header: "Búsqueda general"
        footer: SearchFiles.available
            ? "Los archivos salen de plocate, que tiene su propio índice y lo actualiza una vez al día."
            : "plocate no está instalado: los archivos no aparecen. Instálalo con ./install.sh."

        ToggleRow {
            title: "Incluir archivos"
            subtitle: "Al buscar con Super + Espacio. El modo Archivos los busca siempre."
            enabled: SearchFiles.available
            checked: SearchFiles.inGeneral
            onToggled: SearchFiles.setInGeneral(!SearchFiles.inGeneral)
        }

        SettingsRow {
            title: "Buscar en la web con"

            SegmentedControl {
                options: root.engineOptions
                current: WebSearch.engine.id
                onSelected: value => WebSearch.setEngine(value)
            }
        }
    }

    SettingsGroup {
        header: "Portapapeles"
        footer: "Con Ctrl + Enter solo se copia, aunque esto esté activado. "
                + "Shift + Supr borra una entrada del historial."

        ToggleRow {
            title: "Pegar al elegir"
            subtitle: "Lo pega en la ventana donde estabas, como Win + V. Desactivado, solo lo copia."
            enabled: SearchClipboard.available
            checked: SearchClipboard.pastes
            onToggled: SearchClipboard.setPastes(!SearchClipboard.pastes)
        }
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
        footer: "Los de Super + Espacio, Super + Shift + V y Super + , se cambian en "
                + "hypr/theme/config/keybindings.lua. Los demás funcionan con Spotlight abierto."

        SettingsRow {
            title: "Abrir Spotlight"
            value: "Super + Espacio"
        }

        SettingsRow {
            title: "Abrir el portapapeles"
            value: "Super + Shift + V"
        }

        SettingsRow {
            title: "Aplicaciones · Archivos · Portapapeles"
            value: "Super + 1 · 2 · 3"
        }

        SettingsRow {
            title: "Cambiar de modo"
            value: "Tab"
        }

        SettingsRow {
            title: "Abrir otra ventana · Mostrar en carpeta · Solo copiar"
            value: "Ctrl + Enter"
        }

        SettingsRow {
            title: "Abrir Ajustes"
            value: "Super + ,"
        }
    }
}
