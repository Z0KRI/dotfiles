// La ventana de la island. Nunca cambia de tamaño: es del tamaño de
// la pantalla y la island se anima DENTRO.
//
// Redimensionar una layer surface cuesta un ciclo configure/ack, y hasta que
// llega el frame del tamaño nuevo el compositor pinta el búfer viejo estirado.
// En una animación eso se ve como un tirón al abrir y un fogonazo al cerrar.
//
// Ser del tamaño de la pantalla no le quita sitio a nadie ni se traga clics:
// no reserva zona exclusiva, y lo que recibe entrada lo decide `maskItem`. Con
// `maskItem` en null la región queda vacía y el ratón pasa de largo.

import QtQuick
import Quickshell
import Quickshell.Wayland

PanelWindow {
    id: root

    default property alias content: contentHolder.data

    // El item que recibe el ratón. La plantilla no sabe cuál es: lo rellena la
    // feature, que es la única que conoce su contenido.
    property Item maskItem: null

    property string namespace: "z0-island"

    // Las cuatro anclas: cubre la pantalla entera.
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    color: "transparent"
    exclusionMode: ExclusionMode.Ignore

    WlrLayershell.namespace: root.namespace
    WlrLayershell.layer: WlrLayer.Top

    mask: Region {
        item: root.maskItem
    }

    Item {
        id: contentHolder
        anchors.fill: parent
    }
}