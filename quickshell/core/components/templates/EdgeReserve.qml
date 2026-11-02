// TEMPLATE: una ventana invisible que solo aparta las ventanas de un borde.
//
// ¿Por qué existe? El marco es UNA ventana del tamaño de la pantalla, y una
// ventana de capa solo puede reservar espacio contra el borde al que está
// pegada: anclada a los cuatro, no reserva nada. Así que el marco no empuja
// a nadie, y en cada borde hay una de estas, de 1 × 1 px, sin dibujo y sin
// ratón, que le dice a Hyprland "estos N px son míos".
//
// gaps_out de Hyprland se cuenta DESDE lo reservado: con 6 px de marco y
// gaps_out = 10, las ventanas quedan a 10 px del marco, no de la pantalla.

import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    // "top", "bottom", "left" o "right".
    property string edge: "top"

    // Cuánto reserva, en px. 0 = nada (sigue existiendo, no estorba).
    property int size: 0

    anchors.top: root.edge === "top"
    anchors.bottom: root.edge === "bottom"
    anchors.left: root.edge === "left"
    anchors.right: root.edge === "right"

    // Poner exclusiveZone ya cambia exclusionMode a Normal: reserva esto.
    exclusiveZone: root.size

    implicitWidth: 1
    implicitHeight: 1
    color: "transparent"

    // Una región vacía: los clics la atraviesan.
    mask: Region {}

    WlrLayershell.namespace: "z0-reserve"
    WlrLayershell.layer: WlrLayer.Bottom
    WlrLayershell.keyboardFocus: WlrKeyboardFocus.None
}
