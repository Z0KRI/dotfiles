// Menú del logo de Arch: sesión y equipo, al estilo del menú Apple.
// Declara QUÉ opciones hay; lo que hace cada una vive en domain.

import QtQuick
import Quickshell
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.templates
import qs.domain.session

DropdownWindow {
    id: root

    // El botón de la barra al que se pega el menú.
    required property Item anchorItem
    anchor.item: root.anchorItem

    menuWidth: 250

    // Cierra el menú y ejecuta la acción.
    function run(action): void {
        root.close();
        action();
    }

    MenuItem {
        icon: ""   // Lucide: info
        text: "Acerca de este equipo"
        enabled: false   // su ventana la haremos después
    }

    Separator {}

    MenuItem {
        icon: ""   // Lucide: circle-x
        text: "Forzar salida"
        onTriggered: root.run(() => SessionActions.forceQuit())
    }

    Separator {}

    MenuItem {
        icon: ""   // Lucide: moon
        text: "Reposo"
        onTriggered: root.run(() => SessionActions.suspend())
    }

    MenuItem {
        icon: ""   // Lucide: rotate-ccw
        text: "Reiniciar"
        onTriggered: root.run(() => SessionActions.reboot())
    }

    MenuItem {
        icon: ""   // Lucide: power
        text: "Apagar equipo"
        onTriggered: root.run(() => SessionActions.powerOff())
    }

    Separator {}

    MenuItem {
        icon: ""   // Lucide: lock
        text: "Bloquear pantalla"
        onTriggered: root.run(() => SessionActions.lock())
    }

    MenuItem {
        icon: ""   // Lucide: log-out
        text: "Cerrar sesión de " + SessionActions.userName
        onTriggered: root.run(() => SessionActions.logout())
    }
}