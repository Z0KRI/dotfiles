// CASO DE USO: la ventana de Ajustes: si está abierta, qué sección se ve y el
// historial de navegación (los botones ‹ › de la barra de herramientas).
// Es el equivalente de LauncherControl, más un "router" pequeño: como el
// Router de Angular, guarda dónde estás y de dónde vienes.
//
// Reglas:
//   - Abrir sin sección vuelve a la última que viste, como en macOS.
//   - Ir a otra sección guarda la actual en el historial y borra el
//     "adelante".
//   - Al cerrar se olvida el historial; la sección se recuerda.
//
// Cualquiera puede pedir una sección: el menú de Arch abre "about", el
// Centro de control abre "wifi", "bluetooth" o "sound".

pragma Singleton

import Quickshell

Singleton {
    id: root

    property bool shown: false
    property string section: "appearance"

    property var past: []
    property var future: []

    readonly property bool canGoBack: root.past.length > 0
    readonly property bool canGoForward: root.future.length > 0

    function open(section): void {
        if (section)
            root.go(section);
        root.shown = true;
    }

    function close(): void {
        root.shown = false;
        root.past = [];
        root.future = [];
    }

    function toggle(): void {
        if (root.shown)
            root.close();
        else
            root.open("");
    }

    function go(section): void {
        if (!section || section === root.section)
            return;

        root.past = root.past.concat([root.section]);
        root.future = [];
        root.section = section;
    }

    function back(): void {
        if (!root.canGoBack)
            return;

        root.future = [root.section].concat(root.future);
        root.section = root.past[root.past.length - 1];
        root.past = root.past.slice(0, -1);
    }

    function forward(): void {
        if (!root.canGoForward)
            return;

        root.past = root.past.concat([root.section]);
        root.section = root.future[0];
        root.future = root.future.slice(1);
    }
}
