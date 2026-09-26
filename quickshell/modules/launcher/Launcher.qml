import Quickshell
import Quickshell.Io
import qs.core.components.templates

Scope {
    id: root

    property bool shown: false

    IpcHandler {
        target: "launcher"

        function toggle(): void {
            root.shown = !root.shown;
        }
        function open(): void {
            root.shown = true;
        }
        function close(): void {
            root.shown = false;
        }
    }

    LazyLoader {
        active: root.shown

        component: OverlayWindow {
            namespace: "z0-launcher"
            onDismissed: root.shown = false

            LauncherPanel {
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                anchors.topMargin: parent.height * 0.25

                onDismissed: root.shown = false
                onLaunched: root.shown = false
            }
        }
    }
}
