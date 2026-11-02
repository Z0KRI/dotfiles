// La barra de menús, ahora como marco: una figura negra alrededor de cada
// pantalla con dos pestañas arriba (ver BarFrame). Una por monitor.
//
// Cada pantalla lleva dos cosas:
//   - el marco (BarFrame): lo que se ve y se toca. No aparta ventanas.
//   - cuatro EdgeReserve: lo que aparta las ventanas, un borde cada una.
//
// Cuándo hay marco, cuándo se esconden las pestañas, si se empujan ventanas
// y si la franja se ve sólida lo decide BarVisibility; aquí solo se conecta.
//
// Por IPC, el panel de notificaciones (en el monitor enfocado):
//   qs ipc call notifications toggle|open|close

import QtQuick
import Quickshell
import Quickshell.Io
import qs.core.theme
import qs.core.components.templates
import qs.domain.desktop
import qs.domain.notifications

Scope {
    id: root

    IpcHandler {
        target: "notifications"

        function toggle(): void {
            NotificationCenter.toggleHere();
        }
        function open(): void {
            NotificationCenter.openHere();
        }
        function close(): void {
            NotificationCenter.close();
        }
    }

    Variants {
        model: Quickshell.screens

        Scope {
            id: perScreen

            required property var modelData

            // Lo que se aparta en cada borde. Con marco, su grosor en los
            // cuatro lados; arriba, además, la barra, salvo cuando se esconde
            // sola (entonces se encima sobre las ventanas, como antes).
            readonly property int reserveSide: BarVisibility.framed(perScreen.modelData)
                ? Theme.frame.thickness
                : 0
            readonly property int reserveTop: perScreen.reserveSide
                + (BarVisibility.reserveSpace(perScreen.modelData) ? Theme.glass.barHeight : 0)

            // A la derecha, además, el panel de notificaciones mientras está
            // abierto en esta pantalla: las ventanas se angostan y Hyprland
            // las reacomoda con su animación, en vez de quedar debajo.
            readonly property int reserveRight: perScreen.reserveSide
                + (NotificationCenter.isOpenOn(perScreen.modelData.name)
                   ? Theme.frame.notificationsWidth
                   : 0)

            BarFrame {
                screen: perScreen.modelData
            }

            EdgeReserve {
                screen: perScreen.modelData
                edge: "top"
                size: perScreen.reserveTop
            }

            EdgeReserve {
                screen: perScreen.modelData
                edge: "left"
                size: perScreen.reserveSide
            }

            EdgeReserve {
                screen: perScreen.modelData
                edge: "right"
                size: perScreen.reserveRight
            }

            EdgeReserve {
                screen: perScreen.modelData
                edge: "bottom"
                size: perScreen.reserveSide
            }
        }
    }
}
