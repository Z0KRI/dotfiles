// Lo que va dentro del cajón de Spotlight. Es el único que tiene estado de
// pantalla (lo que llevas escrito); el modo vive en LauncherControl porque
// también lo cambian los atajos de Hyprland.
//
// Sale del borde de abajo, así que se lee de abajo hacia arriba:
//
//   arriba     los modos (Todo, Apps, Archivos)
//   en medio   los resultados, con el MEJOR justo encima del campo
//   abajo      el campo de búsqueda, pegado al marco
//
// ¿Por qué al revés? Porque tus ojos ya están en el campo. Lo que vas a
// elegir con Enter queda pegado a lo que escribes, y las flechas suben por la
// lista como suben por el historial de una terminal.
//
// El flujo de una tecla:
//   SearchField  →  query  →  Spotlight.prepare()   (lanza plocate si toca)
//                         →  Spotlight.results()   (binding: lee lo que hay)
//                         →  LauncherCatalog.decorate()  (glifo, "Abrir ↵"…)
//                         →  bottomUp()            (el orden de abajo arriba)
//                         →  ResultList
//
// Teclas (además de ↑ ↓ y Enter):
//   Ctrl + Enter        la acción alternativa: abrir otra ventana, mostrar
//                       en carpeta
//   Super/Ctrl + 1, 2   Aplicaciones, Archivos (otra vez: Todo)
//   Super/Ctrl + 3      el portapapeles (cierra Spotlight y abre su panel)
//   Tab / Shift + Tab   el modo siguiente / anterior
//   Retroceso           con el campo vacío, vuelve a Todo
//   Esc                 borra lo escrito; con el campo vacío, cierra

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.clipboard
import qs.domain.launcher

Item {
    id: root

    property string query: ""
    readonly property string mode: LauncherControl.mode

    readonly property var results: root.bottomUp(
        Spotlight.results(root.query, root.mode).map(LauncherCatalog.decorate))

    signal dismissed()
    signal launched()

    readonly property int inset: Theme.frame.inset
    readonly property int gap: 10

    // El mismo campo que el del portapapeles: 34 de alto, en cápsula.
    readonly property int fieldHeight: 34

    // La lista mide lo que tiene, hasta un tope; sin resultados, 0 y el
    // cajón se encoge a los modos y el campo.
    readonly property real listHeight: root.results.length > 0
        ? Math.min(list.contentHeight, Theme.frame.spotlightMaxList)
        : 0

    implicitWidth: Theme.frame.spotlightWidth
    implicitHeight: root.inset + scopes.height + root.gap
                    + (root.listHeight > 0 ? root.listHeight + root.gap : 0)
                    + root.fieldHeight + root.inset

    onQueryChanged: Spotlight.prepare(root.query, root.mode)

    onModeChanged: {
        Spotlight.begin(root.mode);
        Spotlight.prepare(root.query, root.mode);
    }

    // El dominio entrega cada sección con su encabezado ARRIBA:
    //   [Aplicaciones, a1, a2, Archivos, f1, Web, w1]
    // La lista va de abajo hacia arriba (el índice 0 queda abajo), así que
    // cada encabezado tiene que ir al FINAL de su sección para verse arriba
    // de ella. Lo que no tiene encabezado (una dirección, un comando) se
    // queda al principio: pegado al campo.
    function bottomUp(list) {
        const out = [];
        let section = [];
        let header = null;

        const flush = () => {
            out.push(...section);
            if (header)
                out.push(header);
            section = [];
            header = null;
        };

        for (let i = 0; i < list.length; ++i) {
            if (list[i].kind === "header") {
                flush();
                header = list[i];
            } else {
                section.push(list[i]);
            }
        }
        flush();

        return out;
    }

    function activate(entry, alternate): void {
        if (Spotlight.activate(entry, alternate))
            root.launched();
    }

    // Tocar el chip del modo en el que ya estás vuelve a Todo.
    function toggleMode(mode): void {
        LauncherControl.setMode(root.mode === mode ? "all" : mode);
    }

    Column {
        x: root.inset
        y: root.inset
        width: parent.width - root.inset * 2
        spacing: root.gap

        // ── Los modos ──
        ScopeButtons {
            id: scopes

            options: LauncherCatalog.modes
            current: root.mode

            onSelected: value => {
                LauncherControl.setMode(value);
                search.focusInput();
            }
        }

        // ── Los resultados ──
        ResultList {
            id: list

            width: parent.width
            height: root.listHeight
            visible: root.listHeight > 0
            model: root.results

            // El índice 0 abajo, pegado al campo.
            verticalLayoutDirection: ListView.BottomToTop

            contentColor: Theme.glass.content
            selectionColor: Qt.alpha(Theme.colors.accent, 0.82)
            selectedContent: "#ffffff"
            rowHeight: 48
            iconSize: 34
            titleSize: Theme.font.normal
            tileColor: Qt.rgba(1, 1, 1, 0.14)
            glyphColor: Theme.glass.content

            onActivated: entry => root.activate(entry, false)
        }

        // ── El campo ──
        SearchField {
            id: search

            width: parent.width
            height: root.fieldHeight
            implicitHeight: root.fieldHeight

            radius: height / 2
            color: Qt.rgba(1, 1, 1, 0.08)

            padding: 12
            fontSize: 13
            contentColor: Theme.glass.content
            glyph: LauncherCatalog.find(root.mode)?.glyph ?? Theme.systemIcons.search
            placeholder: LauncherCatalog.placeholderFor(root.mode)

            onSearched: value => root.query = value

            // La lista está al revés: ↑ es "el siguiente resultado".
            onNavigated: delta => list.move(-delta)

            onAccepted: root.activate(list.currentEntry, false)
            onAlternateAccepted: root.activate(list.currentEntry, true)
            onTabbed: delta => LauncherControl.cycle(delta)

            onShortcut: number => {
                const mode = LauncherCatalog.modeForNumber(number);
                if (mode === "clipboard")
                    ClipboardControl.open();
                else if (mode !== "")
                    root.toggleMode(mode);
            }

            onBackspacedEmpty: {
                if (root.mode !== "all")
                    LauncherControl.setMode("all");
            }

            onDismissed: {
                if (search.text !== "")
                    search.clear();
                else
                    root.dismissed();
            }
        }
    }

    Component.onCompleted: {
        Spotlight.begin(root.mode);
        search.focusInput();
    }
}
