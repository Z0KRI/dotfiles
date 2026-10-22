// Menú del logo de Arch: sesión y equipo, al estilo del menú Apple.
// Declara QUÉ opciones hay; lo que hace cada una vive en domain.

import QtQuick
import Quickshell
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.templates
import qs.domain.session
import qs.domain.settings

DropdownWindow {
    id: root

    // El botón de la barra al que se pega el menú.
    required property Item anchorItem
    anchor.item: root.anchorItem

    menuWidth: 250

    // root.run(acción) cierra el menú y luego la ejecuta (viene de DropdownWindow).

    MenuItem {
        icon: Theme.systemIcons.info
        text: "Acerca de este equipo"
        onTriggered: root.run(() => SettingsControl.open("about"))
    }

    Separator {}

    MenuItem {
        icon: Theme.systemIcons.settings
        text: "Ajustes del sistema…"
        shortcut: "Super ,"
        onTriggered: root.run(() => SettingsControl.open(""))
    }

    Separator {}

    MenuItem {
        icon: Theme.systemIcons.forceQuit
        text: "Forzar salida"
        onTriggered: root.run(() => SessionActions.forceQuit())
    }

    Separator {}

    MenuItem {
        icon: Theme.systemIcons.moon
        text: "Reposo"
        onTriggered: root.run(() => SessionActions.suspend())
    }

    MenuItem {
        icon: Theme.systemIcons.restart
        text: "Reiniciar"
        onTriggered: root.run(() => SessionActions.reboot())
    }

    MenuItem {
        icon: Theme.systemIcons.power
        text: "Apagar equipo"
        onTriggered: root.run(() => SessionActions.powerOff())
    }

    Separator {}

    MenuItem {
        icon: Theme.systemIcons.lock
        text: "Bloquear pantalla"
        onTriggered: root.run(() => SessionActions.lock())
    }

    MenuItem {
        icon: Theme.systemIcons.logout
        text: "Cerrar sesión de " + SessionActions.userName
        onTriggered: root.run(() => SessionActions.logout())
    }
}
