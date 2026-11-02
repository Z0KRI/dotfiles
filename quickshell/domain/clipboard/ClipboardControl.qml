// CASO DE USO: si el panel del portapapeles está abierto.
// Reglas:
//   - Vive en la esquina de abajo a la derecha. Spotlight sale del mismo
//     borde de abajo: abrir uno cierra el otro, en las dos direcciones.
//   - Pedirlo abierto cuando ya lo está lo cierra: así el mismo atajo
//     (Super + Shift + V) abre y cierra.
//
// La regla de "uno a la vez" vive solo aquí: este archivo conoce a
// LauncherControl, pero LauncherControl no conoce a este. Si los dos se
// importaran entre sí, los módulos quedarían en círculo.

pragma Singleton

import QtQuick
import Quickshell
import qs.domain.launcher

Singleton {
    id: root

    property bool shown: false

    function open(): void {
        LauncherControl.close();
        SearchClipboard.refresh();
        root.shown = true;
    }

    function close(): void {
        root.shown = false;
    }

    function toggle(): void {
        if (root.shown)
            root.close();
        else
            root.open();
    }

    // Spotlight se abrió (con la lupa, con Super + Espacio, por IPC…).
    Connections {
        target: LauncherControl

        function onShownChanged() {
            if (LauncherControl.shown)
                root.close();
        }
    }
}
