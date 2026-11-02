// CASO DE USO: si el panel del portapapeles está abierto.
// Reglas:
//   - Vive en la esquina de abajo a la derecha. El borde de abajo lo
//     comparte con Spotlight, Mission Control y los fondos: uno a la vez
//     (lo decide BottomEdge).
//   - Pedirlo abierto cuando ya lo está lo cierra: así el mismo atajo
//     (Super + Shift + V) abre y cierra.

pragma Singleton

import QtQuick
import Quickshell
import qs.domain.desktop

Singleton {
    id: root

    readonly property bool shown: BottomEdge.owner === "clipboard"

    function open(): void {
        SearchClipboard.refresh();
        BottomEdge.claim("clipboard");
    }

    function close(): void {
        BottomEdge.release("clipboard");
    }

    function toggle(): void {
        if (root.shown)
            root.close();
        else
            root.open();
    }
}
