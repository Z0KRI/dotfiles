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
            LauncherControl.open()
        }
        function close(): void {
            LauncherControl.close()
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
