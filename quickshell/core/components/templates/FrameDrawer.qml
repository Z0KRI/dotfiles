// TEMPLATE: el contenido de un cajón del marco (Centro de control,
// calendario, menú del sistema).
//
// Reemplaza a DropdownWindow. Ya no es una ventana aparte pegada a un botón:
// es una pieza que el marco pone dentro de su figura (FrameWindow, huecos
// rightPanel y sidePanel). Por eso no dibuja fondo ni borde: el fondo es el
// negro del marco.
//
// Conserva la forma de usarse de DropdownWindow para que los menús cambien
// poco: las opciones van entre llaves, en columna, y root.run(acción) cierra
// y luego ejecuta.

import QtQuick

Item {
    id: root

    default property alias content: column.data

    // ¿Está abierto? Lo pone quien lo usa. La figura la anima el marco;
    // aquí solo se avisa, con opened() y closed(), a lo que tenga que
    // encenderse o apagarse (la búsqueda de Wi-Fi, por ejemplo).
    property bool open: false

    // Ancho total, con el aire incluido. El marco lo lee de implicitWidth.
    property int panelWidth: 260
    property int padding: 5

    // Arriba puede ir distinto: el cajón de la pestaña derecha ya tiene el
    // aire de la pestaña encima.
    property int topPadding: root.padding

    // Pide al marco que lo cierre. El marco decide (un solo cajón a la vez).
    signal closeRequested()

    signal opened()
    signal closed()

    function close(): void {
        root.closeRequested();
    }

    // Cierra y luego ejecuta la acción.
    function run(action): void {
        root.close();
        action();
    }

    // El marco lo crea ya abierto (vive solo mientras se ve). Un
    // onOpenChanged no se dispara con el valor inicial, así que el primer
    // aviso va aquí.
    Component.onCompleted: {
        if (root.open)
            root.opened();
    }

    onOpenChanged: {
        if (root.open)
            root.opened();
        else
            root.closed();
    }

    implicitWidth: root.panelWidth
    implicitHeight: column.implicitHeight + root.topPadding + root.padding

    Column {
        id: column

        x: root.padding
        y: root.topPadding
        width: root.panelWidth - root.padding * 2
        spacing: 0
    }
}
