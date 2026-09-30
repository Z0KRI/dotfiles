// TEMPLATE: menú desplegable anclado a un elemento.
// Se cierra solo al hacer clic fuera o con Escape.
// El contenido (las opciones) lo pone quien lo usa.

import QtQuick
import Quickshell
import qs.core.theme
import qs.core.components.atoms

PopupWindow {
    id: root

    default property alias content: column.data

    property int menuWidth: 260
    property int gap: 6        // separación entre el botón y el menú
    property int padding: 5

    // Para botones del lado derecho de la barra: el menú se alinea al
    // borde derecho del botón y crece hacia la izquierda.
    property bool alignRight: false

    // "¿Está abierto?" es visible y nada más: una sola fuente de verdad.
    function open(): void { root.visible = true; }
    function close(): void { root.visible = false; }
    function toggle(): void { root.visible = !root.visible; }

    // Cierra el menú y ejecuta la acción.
    function run(action): void {
        root.close();
        action();
    }

    // Clic fuera = cerrar. Quickshell pone visible en false por su cuenta.
    grabFocus: true
    color: "transparent"

    anchor.edges: root.alignRight ? (Edges.Bottom | Edges.Right) : (Edges.Bottom | Edges.Left)
    anchor.gravity: root.alignRight ? (Edges.Bottom | Edges.Left) : (Edges.Bottom | Edges.Right)

    implicitWidth: root.menuWidth
    implicitHeight: panel.implicitHeight + root.gap

    Surface {
        id: panel

        width: parent.width
        implicitHeight: column.implicitHeight + root.padding * 2

        // Aparece bajando un poco y desvaneciéndose hacia dentro.
        y: root.visible ? root.gap : root.gap - 4
        opacity: root.visible ? 1 : 0

        Behavior on y {
            NumberAnimation { duration: 140; easing.type: Easing.OutCubic }
        }
        Behavior on opacity {
            NumberAnimation { duration: 140 }
        }

        // Mismo fondo que tu launcher, un poco más opaco para leer bien.
        color: Qt.alpha(Theme.colors.base100, 0.85)
        radius: 10
        border.width: 1
        border.color: Theme.glass.border

        focus: true
        Keys.onEscapePressed: root.close()

        Column {
            id: column
            anchors.fill: parent
            anchors.margins: root.padding
            spacing: 0
        }
    }
}