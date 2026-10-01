pragma Singleton

// El estado de la island que OTRAS features necesitan leer. No decide nada:
// lo rellena el módulo. Está aquí para que la barra sepa apartarse.

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    // Nombre del ocupante que manda; "" cuando no hay ninguno.
    property string occupant: ""

    // ¿el ratón está encima del cuerpo?
    property bool hovered: false

    readonly property bool open: root.occupant !== ""

    // En qué monitor se dibuja: el que tiene el ratón.
    //
    // Hyprland no publica la posición del cursor y Quickshell tampoco la
    // expone, pero no hace falta: con `input:follow_mouse` distinto de 0 —el
    // valor por defecto— pasar el ratón a otro monitor ya cambia el monitor
    // enfocado, así que seguirlo en vivo es seguir al ratón.
    //
    // Antes esto se congelaba al aparecer, para que no saltara de pantalla a
    // media animación. El remedio era peor: con dos monitores la island salía
    // donde estaba la ventana enfocada y no donde estabas tú, y el hover no
    // llegaba nunca. Y el salto no ocurre, porque mientras tengas el ratón
    // encima de la island ese monitor ya es el enfocado.
    readonly property string screenName: {
        const monitor = Hyprland.focusedMonitor
        if (monitor && monitor.name)
            return monitor.name

        return Quickshell.screens.length > 0 ? Quickshell.screens[0].name : ""
    }

    // La ZONA de la island en esa pantalla: el cuerpo más su holgura. Vacía
    // cuando no hay island.
    //
    // La barra se resta este hueco de su región de entrada. Sin eso, en
    // pantalla completa la barra sube a la capa overlay, queda por encima y se
    // lleva el ratón que iba a la island.
    property rect bodyRect: Qt.rect(0, 0, 0, 0)
}