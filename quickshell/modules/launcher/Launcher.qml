// La feature de Spotlight: un cajón que sale del borde de abajo del marco, al
// centro, en el monitor enfocado. Su contenido existe solo mientras se ve.
//
// Por IPC, para los atajos de Hyprland:
//   qs ipc call launcher open|close|toggle   la búsqueda general
//   qs ipc call launcher mode apps           abrir directo en un modo
//                                            (apps | files | all); si ya
//                                            está abierto en ese modo, lo cierra
//   qs ipc call launcher mode clipboard      lo de antes: ahora abre el panel
//                                            del portapapeles

import QtQuick
import Quickshell
import Quickshell.Io

import qs.core.theme
import qs.core.components.templates
import qs.domain.clipboard
import qs.domain.desktop
import qs.domain.launcher

Scope {
    id: root

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            LauncherControl.toggle();
        }
        function open(): void {
            LauncherControl.open();
        }
        function close(): void {
            LauncherControl.close();
        }
        function mode(name: string): void {
            if (name === "clipboard")
                ClipboardControl.toggle();
            else
                LauncherControl.openMode(name);
        }
    }

    DrawerWindow {
        id: drawer

        namespace: "z0-launcher"
        attach: "bottom"
        open: LauncherControl.shown

        bodyWidth: Theme.frame.spotlightWidth
        closedWidth: Theme.frame.spotlightClosedWidth

        // Lo que mide su contenido; mientras no existe, lo mínimo (los
        // modos y el campo), para que crezca hacia algo con sentido.
        bodyHeight: panel.item ? panel.item.implicitHeight : 120

        bottomInset: BarVisibility.focusedFramed ? Theme.frame.thickness : 0

        onDismissed: LauncherControl.close()

        Loader {
            id: panel

            anchors.fill: parent
            active: drawer.present

            sourceComponent: LauncherPanel {
                onDismissed: LauncherControl.close()
                onLaunched: LauncherControl.close()
            }
        }
    }
}
