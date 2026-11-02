// La feature del portapapeles: un panel en la esquina de abajo a la derecha,
// pegado al marco, en el monitor enfocado. Si ahí está abierto el panel de
// notificaciones, se pega a la orilla de ese panel en vez de quedar debajo.
//
// Por IPC (Super + Shift + V):
//   qs ipc call clipboard toggle|open|close

import QtQuick
import Quickshell
import Quickshell.Io

import qs.core.theme
import qs.core.components.templates
import qs.domain.clipboard
import qs.domain.desktop
import qs.domain.notifications

Scope {
    id: root

    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            ClipboardControl.toggle();
        }
        function open(): void {
            ClipboardControl.open();
        }
        function close(): void {
            ClipboardControl.close();
        }
    }

    DrawerWindow {
        id: drawer

        namespace: "z0-clipboard"
        attach: "corner"
        open: ClipboardControl.shown

        bodyWidth: Theme.frame.clipboardWidth
        bodyHeight: Theme.frame.clipboardHeight

        readonly property real frame: BarVisibility.focusedFramed ? Theme.frame.thickness : 0

        bottomInset: drawer.frame
        rightInset: drawer.frame
                    + (NotificationCenter.openOnFocused ? Theme.frame.notificationsWidth : 0)

        onDismissed: ClipboardControl.close()

        Loader {
            anchors.fill: parent
            active: drawer.present

            sourceComponent: ClipboardPanel {
                onDismissed: ClipboardControl.close()
            }
        }
    }
}
