// La feature de Mission Control: un cajón de tarjetas que sale del borde de
// abajo, al centro, con un escritorio por tarjeta. La pantalla de atrás se
// oscurece un poco mientras está abierto.
//
// Por IPC (F3 en el teclado Apple, CTRL + ↑ en cualquiera):
//   qs ipc call mission toggle|open|close

import QtQuick
import Quickshell
import Quickshell.Io

import qs.core.theme
import qs.core.components.templates
import qs.domain.desktop

Scope {
    id: root

    IpcHandler {
        target: "mission"

        function toggle(): void {
            MissionControl.toggle();
        }
        function open(): void {
            MissionControl.open();
        }
        function close(): void {
            MissionControl.close();
        }
    }

    DrawerWindow {
        id: drawer

        namespace: "z0-mission"
        attach: "bottom"
        open: MissionControl.shown
        dim: Theme.frame.missionDim

        readonly property int fits: Theme.deckFits(drawer.width, 160)

        bodyWidth: Theme.deckWidth(Math.min(MissionControl.desks.length, drawer.fits))
        bodyHeight: Theme.frame.deckHeight
        closedWidth: Theme.frame.deckClosedWidth

        bottomInset: BarVisibility.focusedFramed ? Theme.frame.thickness : 0

        onDismissed: MissionControl.close()

        Loader {
            anchors.fill: parent
            active: drawer.present

            sourceComponent: MissionPanel {
                onDismissed: MissionControl.close()
            }
        }
    }
}
