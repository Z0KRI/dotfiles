// TEMPLATE: ventana pegada al borde superior.
// Su altura la dicta el contenido. Ofrece: ocultarse sola, reservar espacio,
// dibujarse sobre pantalla completa, un fondo sólido de lado a lado
// y quedarse visible mientras haya algo abierto (keepRevealed).

import QtQuick
import Quickshell
import Quickshell.Wayland
import qs.core.theme

PanelWindow {
    id: root

    default property alias content: contentHolder.data

    property string namespace: "z0-bar"

    // --- Mecanismos ---
    property bool autoHide: false
    property bool reserveSpace: true
    property bool aboveFullscreen: false
    property bool solid: false
    property color solidColor: Theme.colors.base800 // TODO: definir un color para la barra

    // Mientras sea true, la barra no se esconde (ej. un menú abierto).
    property bool keepRevealed: false

    property int revealStrip: 2
    property int hideDelay: 400

    property bool revealed: !root.autoHide

    anchors {
        top: true
        left: true
        right: true
    }

    // La altura sale del contenido. Nunca 0: una ventana de capa
    // anclada solo arriba no puede medir 0 de alto.
    implicitHeight: Math.max(1, contentHolder.implicitHeight)
    color: "transparent"

    exclusionMode: root.reserveSpace ? ExclusionMode.Auto : ExclusionMode.Ignore

    WlrLayershell.namespace: root.namespace
    WlrLayershell.layer: root.aboveFullscreen ? WlrLayer.Overlay : WlrLayer.Top

    // Solo esta zona recibe el mouse; fuera de ella los clics pasan
    // a las ventanas de abajo.
    mask: Region {
        width: root.width
        height: root.revealed ? root.height : root.revealStrip
    }

    onAutoHideChanged: {
        hideTimer.stop();
        root.revealed = !root.autoHide;
    }

    // Al cerrarse lo que la mantenía visible, si el mouse ya no está
    // encima, empieza la cuenta para esconderse.
    onKeepRevealedChanged: {
        if (root.keepRevealed) {
            hideTimer.stop();
            root.revealed = true;
        } else if (root.autoHide && !barHover.hovered) {
            hideTimer.restart();
        }
    }

    // Raíz de todo lo visible. El detector de la barra vive aquí, como
    // ANCESTRO del contenido: el hover llega primero a los botones y luego
    // sube hasta aquí. Nada queda encima de los botones.
    Item {
        anchors.fill: parent

        HoverHandler {
            id: barHover

            onHoveredChanged: {
                if (!root.autoHide)
                    return;

                if (hovered) {
                    hideTimer.stop();
                    root.revealed = true;
                } else {
                    hideTimer.restart();
                }
            }
        }

        // Todo lo que se desliza junto: el fondo sólido y el contenido.
        Item {
            id: slider

            width: parent.width
            height: parent.height
            y: root.revealed ? 0 : -height

            Behavior on y {
                NumberAnimation {
                    duration: 250
                    easing.type: Easing.OutCubic
                }
            }

            // Fondo de lado a lado. "Apagado" es el mismo color con alfa 0,
            // así la transición no pasa por negro.
            Rectangle {
                anchors.fill: parent
                color: root.solid ? root.solidColor : Qt.alpha(root.solidColor, 0)

                Behavior on color {
                    ColorAnimation {
                        duration: Theme.motion.duration
                        easing.type: Easing.OutCubic
                    }
                }
            }

            // Hueco del contenido. Su alto es el de sus hijos.
            Item {
                id: contentHolder
                width: parent.width
                implicitHeight: childrenRect.height
            }
        }
    }

    Timer {
        id: hideTimer
        interval: root.hideDelay
        onTriggered: {
            if (!root.keepRevealed)
                root.revealed = false;
        }
    }
}