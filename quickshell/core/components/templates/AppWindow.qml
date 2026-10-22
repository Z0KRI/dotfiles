// TEMPLATE: ventana de aplicación al estilo macOS Golden Gate. Barra lateral
// de vidrio de borde a borde con los botones de ventana arriba, y a la
// derecha una barra de herramientas sobre el contenido.
//
// A diferencia de tus PanelWindow (barra, isla, launcher), esta es una
// ventana NORMAL: un FloatingWindow es una ventana xdg como la de cualquier
// app. Hyprland la enfoca, la pone en el alt-tab, la mueve con SUPER + clic
// y, como su fondo es transparente, le aplica su desenfoque (blur) detrás de
// la barra lateral. Lo que no hace es decidir si flota: eso lo dice la regla
// de ventana de tu config de Hyprland.
//
// Ranuras (las llena quien la usa):
//   sidebar   lo de la barra lateral, debajo de los botones de ventana
//   toolbar   lo de la barra de herramientas
//   (default) el contenido

import QtQuick
import Quickshell
import qs.core.theme
import qs.core.components.molecules

FloatingWindow {
    id: root

    property alias sidebar: sidebarHolder.data
    property alias toolbar: toolbarHolder.data
    default property alias content: contentHolder.data

    property int sidebarWidth: Theme.window.sidebarWidth

    // Cerrar con el botón rojo o con Ctrl+W. Quien la usa decide qué
    // significa (en Ajustes: descargar la ventana).
    signal closeRequested()

    // Transparente ANTES de mostrarse: así Quickshell pide una superficie con
    // alfa, y Hyprland puede desenfocar lo de atrás. Si empezara opaca, ya no
    // podría volverse transparente.
    color: "transparent"

    implicitWidth: 860
    implicitHeight: 620
    minimumSize: Qt.size(720, 500)

    // Arrastrar la ventana desde las zonas vacías de arriba, como en macOS.
    //
    // Con DragHandler y no con MouseArea: el DragHandler solo se activa al
    // pasar el umbral de arrastre, así un clic en los botones de ventana o en
    // ‹ › sigue siendo clic. Y startSystemMove() tiene que llamarse en medio
    // de un arrastre: le entrega el movimiento a Hyprland.
    component MoveZone: Item {
        DragHandler {
            target: null
            onActiveChanged: {
                if (active)
                    root.startSystemMove();
            }
        }
    }

    Item {
        anchors.fill: parent

        Shortcut {
            sequence: "Ctrl+W"
            onActivated: root.closeRequested()
        }

        // ── Fondos ──────────────────────────────────────────
        Rectangle {
            id: sidebarBackground

            width: root.sidebarWidth
            height: parent.height
            color: Theme.window.sidebar
        }

        Rectangle {
            x: root.sidebarWidth
            width: 1
            height: parent.height
            color: Theme.window.divider
        }

        Rectangle {
            id: contentBackground

            x: root.sidebarWidth + 1
            width: parent.width - x
            height: parent.height
            color: Theme.window.background
        }

        // ── Barra lateral ───────────────────────────────────
        MoveZone {
            width: root.sidebarWidth
            height: Theme.window.toolbarHeight
        }

        WindowControls {
            x: 20
            y: Math.round((Theme.window.toolbarHeight - height) / 2)
            onCloseClicked: root.closeRequested()
        }

        Item {
            id: sidebarHolder

            y: Theme.window.toolbarHeight
            width: root.sidebarWidth
            height: parent.height - y
        }

        // ── Barra de herramientas y contenido ───────────────
        Item {
            x: contentBackground.x
            width: contentBackground.width
            height: Theme.window.toolbarHeight

            MoveZone {
                anchors.fill: parent
            }

            Item {
                id: toolbarHolder
                anchors.fill: parent
            }
        }

        Item {
            id: contentHolder

            x: contentBackground.x
            y: Theme.window.toolbarHeight
            width: contentBackground.width
            height: parent.height - y
        }
    }
}
