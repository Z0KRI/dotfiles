// CASO DE USO: si Spotlight está abierto. Una sola fuente de verdad para el
// atajo (IPC), el botón de la lupa en la barra y el propio panel.

pragma Singleton

import Quickshell

Singleton {
    id: root

    property bool shown: false

    function open(): void { root.shown = true; }
    function close(): void { root.shown = false; }
    function toggle(): void { root.shown = !root.shown; }
}