// REPOSITORIO: el inhibidor de inactividad de Wayland.
// Un IdleInhibitor necesita una ventana: se crea una de 1×1, transparente
// y que no recibe clics, solo mientras está activo.

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Wayland

Singleton {
    id: root

    property bool inhibited: false

    function setInhibited(on): void {
        root.inhibited = on;
    }

    LazyLoader {
        active: root.inhibited

        PanelWindow {
            id: holder

            anchors.top: true
            anchors.left: true
            implicitWidth: 1
            implicitHeight: 1
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore

            // Región vacía: los clics la atraviesan.
            mask: Region {}

            WlrLayershell.namespace: "qs-stay-awake"

            IdleInhibitor {
                window: holder
                enabled: true
            }
        }
    }
}