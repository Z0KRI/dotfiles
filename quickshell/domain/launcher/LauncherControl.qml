// CASO DE USO: si Spotlight está abierto y en qué modo. Una sola fuente de
// verdad para el atajo (IPC), el botón de la lupa en la barra y el propio
// panel.
//
// Los modos son los chips de Spotlight:
//   all        la búsqueda general (Super + Espacio): apps, archivos y web
//   apps       solo aplicaciones
//   files      solo archivos
//
// Spotlight sale del borde de abajo, que comparte con el portapapeles,
// Mission Control y los fondos: uno a la vez. Quién lo tiene lo decide
// BottomEdge; aquí `shown` solo pregunta si es de Spotlight.
//
// Reglas:
//   - Abrir sin modo es abrir la búsqueda general.
//   - Pedir el modo en el que ya estás, con Spotlight abierto, lo cierra:
//     así el mismo atajo abre y cierra, como Super + Espacio.

pragma Singleton

import Quickshell
import qs.domain.desktop

Singleton {
    id: root

    readonly property var modes: ["all", "apps", "files"]

    readonly property bool shown: BottomEdge.owner === "spotlight"
    property string mode: "all"

    function open(): void {
        root.mode = "all";
        BottomEdge.claim("spotlight");
    }

    function close(): void {
        BottomEdge.release("spotlight");
    }

    function toggle(): void {
        if (root.shown)
            root.close();
        else
            root.open();
    }

    // Abrir directo en un modo (atajos de Hyprland, p. ej. Launchpad → apps).
    function openMode(mode): void {
        if (root.modes.indexOf(mode) < 0)
            mode = "all";

        if (root.shown && root.mode === mode) {
            root.close();
            return;
        }

        root.mode = mode;
        BottomEdge.claim("spotlight");
    }

    // Cambiar de modo con Spotlight ya abierto (los chips, Super + 1…3, Tab).
    function setMode(mode): void {
        if (root.modes.indexOf(mode) >= 0)
            root.mode = mode;
    }

    // El modo siguiente o anterior, dando la vuelta: Tab y Shift + Tab.
    function cycle(delta): void {
        const at = root.modes.indexOf(root.mode);
        const count = root.modes.length;
        root.mode = root.modes[(at + delta + count) % count];
    }
}
