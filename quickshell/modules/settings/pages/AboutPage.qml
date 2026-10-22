// Ajustes › Acerca de: el logo de Arch, el nombre del equipo y sus datos.
// Se vuelven a leer cada vez que abres la página (el tiempo encendido cambia).

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.system

SettingsPage {
    id: root

    Component.onCompleted: AboutThisComputer.refresh()

    Column {
        width: parent.width
        spacing: 4
        topPadding: 8
        bottomPadding: 4

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            icon: Theme.systemIcons.arch.icon
            font.family: Theme.systemIcons.arch.family
            size: 76
            color: "#1793d1"   // el azul de Arch
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            topPadding: 6
            text: AboutThisComputer.hostName
            color: Theme.window.text
            font.pixelSize: Theme.window.fontHero
            font.weight: Font.Bold
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: AboutThisComputer.system
            color: Theme.window.textMuted
            font.pixelSize: Theme.window.fontBody
        }
    }

    SettingsGroup {
        SettingsRow {
            glyph: Theme.systemIcons.cpu
            title: "Procesador"
            value: AboutThisComputer.processor
        }

        SettingsRow {
            glyph: Theme.systemIcons.memory
            title: "Memoria"
            value: AboutThisComputer.memory
        }

        SettingsRow {
            glyph: Theme.systemIcons.gpu
            title: "Gráficos"
            value: AboutThisComputer.graphics
        }
    }

    SettingsGroup {
        SettingsRow {
            title: "Kernel"
            value: AboutThisComputer.kernel
        }

        SettingsRow {
            title: "Hyprland"
            value: AboutThisComputer.hyprland
        }

        SettingsRow {
            title: "Quickshell"
            value: AboutThisComputer.quickshell
        }
    }

    SettingsGroup {
        SettingsRow {
            glyph: Theme.systemIcons.user
            title: "Usuario"
            value: AboutThisComputer.userName
        }

        SettingsRow {
            glyph: Theme.systemIcons.clock
            title: "Encendido desde hace"
            value: AboutThisComputer.uptime
        }
    }
}
