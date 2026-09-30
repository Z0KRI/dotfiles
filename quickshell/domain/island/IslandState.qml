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

    // En qué monitor se dibuja. La island existe en todas las pantallas, pero
    // solo se ve en una.
    property string screenName: ""

    // Dónde está el cuerpo, en coordenadas de esa pantalla. Vacío cuando no
    // hay island.
    //
    // Esto no es decoración: la barra ocupa el mismo borde superior y a veces
    // acaba por encima —en pantalla completa sube a la capa overlay—, así que
    // necesita restarse este hueco de su región de entrada. Con eso, quién
    // quede encima deja de importar.
    property rect bodyRect: Qt.rect(0, 0, 0, 0)

    // Se elige al aparecer y no cambia mientras dure. Si siguiera al foco,
    // mover el ratón a otro monitor arrastraría la island a media animación.
    function claimScreen(): void {
        const monitor = Hyprland.focusedMonitor;
        if (monitor && monitor.name) {
            root.screenName = monitor.name;
            return;
        }
        root.screenName = Quickshell.screens.length > 0
            ? Quickshell.screens[0].name
            : "";
    }
}