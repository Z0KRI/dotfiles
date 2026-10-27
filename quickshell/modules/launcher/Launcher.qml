// La feature de Spotlight. Siempre viva, pero la ventana solo existe
// mientras está abierta (LazyLoader).
//
// Por IPC, para los atajos de Hyprland:
//   qs ipc call launcher open|close|toggle   la búsqueda general
//   qs ipc call launcher mode clipboard      abrir directo en un modo
//                                            (apps | files | clipboard | all);
//                                            si ya está abierto en ese modo, lo cierra

import Quickshell
import Quickshell.Io

import qs.domain.launcher
import qs.core.components.templates

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
            LauncherControl.openMode(name);
        }
    }

    LazyLoader {
        active: LauncherControl.shown

        component: OverlayWindow {
            namespace: "z0-launcher"
            onDismissed: LauncherControl.close()

            LauncherPanel {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.25

                onDismissed: LauncherControl.close()
                onLaunched: LauncherControl.close()
            }
        }
    }
}
