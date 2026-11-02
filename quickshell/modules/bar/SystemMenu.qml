// Menú del logo de Arch: sesión y equipo, al estilo del menú Apple.
// Declara QUÉ opciones hay; lo que hace cada una vive en domain.
//
// Sale del borde izquierdo del marco, a media pantalla, como una pestaña
// acostada (BarFrame lo pone en el cajón `sidePanel`).

import QtQuick
import Quickshell
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.templates
import qs.domain.desktop
import qs.domain.session
import qs.domain.settings

FrameDrawer {
    id: root

    panelWidth: 250
    padding: 10

    // root.run(acción) cierra el menú y luego la ejecuta (viene de FrameDrawer).

    // Las filas de este menú: más altas que las de un menú normal (como en el
    // lienzo) y en blanco, sobre el negro del marco.
    component Entry: MenuItem {
        implicitHeight: 32
        radius: 9
        contentColor: Theme.glass.content
    }

    Entry {
        icon: Theme.systemIcons.info
        text: "Acerca de este equipo"
        onTriggered: root.run(() => SettingsControl.open("about"))
    }

    Separator {}

    Entry {
        icon: Theme.systemIcons.settings
        text: "Ajustes del sistema…"
        shortcut: "Super ,"
        onTriggered: root.run(() => SettingsControl.open(""))
    }

    // El selector sale del borde de abajo; lo que estuviera ahí se cierra.
    Entry {
        icon: Theme.systemIcons.launcher.image
        text: "Fondo de pantalla…"
        onTriggered: root.run(() => Wallpapers.open())
    }

    Separator {}

    Entry {
        icon: Theme.systemIcons.forceQuit
        text: "Forzar salida"
        onTriggered: root.run(() => SessionActions.forceQuit())
    }

    Separator {}

    Entry {
        icon: Theme.systemIcons.moon
        text: "Reposo"
        onTriggered: root.run(() => SessionActions.suspend())
    }

    Entry {
        icon: Theme.systemIcons.restart
        text: "Reiniciar"
        onTriggered: root.run(() => SessionActions.reboot())
    }

    Entry {
        icon: Theme.systemIcons.power
        text: "Apagar equipo"
        onTriggered: root.run(() => SessionActions.powerOff())
    }

    Separator {}

    Entry {
        icon: Theme.systemIcons.lock
        text: "Bloquear pantalla"
        onTriggered: root.run(() => SessionActions.lock())
    }

    Entry {
        icon: Theme.systemIcons.logout
        text: "Cerrar sesión de " + SessionActions.userName
        onTriggered: root.run(() => SessionActions.logout())
    }
}
