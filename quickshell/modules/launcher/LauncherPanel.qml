// El panel de Spotlight: la barra con los chips de modo y la lista de
// resultados. Es el único que tiene estado de pantalla (lo que llevas
// escrito); el modo vive en LauncherControl porque también lo cambian los
// atajos de Hyprland.
//
// Aspecto de macOS 27 (Golden Gate): dos piezas de vidrio separadas.
//   - La barra: una cápsula. A la izquierda, el glifo del modo (la lupa en
//     la búsqueda general), igual que el ícono de la categoría en macOS.
//   - Los resultados: un panel aparte, debajo, que cae y se desvanece al
//     aparecer. Íconos grandes y la fila elegida en el color de acento.
// El vidrio en sí (tinte, borde oscuro, reflejo) es el átomo GlassSurface; el
// desenfoque lo pone Hyprland (workspace_windows_rules.lua).
//
// El flujo de una tecla:
//   SearchField  →  query  →  Spotlight.prepare()   (lanza plocate si toca)
//                         →  Spotlight.results()   (binding: lee lo que hay)
//                         →  LauncherCatalog.decorate()  (glifo, "Abrir ↵"…)
//                         →  ResultList
//
// Teclas (además de ↑ ↓ y Enter):
//   Ctrl + Enter        la acción alternativa: abrir otra ventana, mostrar
//                       en carpeta, copiar sin pegar
//   Super/Ctrl + 1…3    Aplicaciones, Archivos, Portapapeles (otra vez: todo)
//   Tab / Shift + Tab   el modo siguiente / anterior
//   Retroceso           con el campo vacío, vuelve a la búsqueda general
//   Shift + Supr        borra la entrada del portapapeles
//   Esc                 borra lo escrito; con el campo vacío, cierra

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.launcher

Item {
    id: root

    property string query: ""
    readonly property string mode: LauncherControl.mode

    readonly property var results: Spotlight.results(root.query, root.mode).map(LauncherCatalog.decorate)
    readonly property bool showResults: root.results.length > 0

    // Lo que la lista muestra. Solo se actualiza cuando HAY algo que mostrar,
    // así al ocultarse se desvanece con los últimos resultados, no con otros.
    property var shownResults: []

    // El espacio entre el borde del panel de resultados y las filas.
    readonly property int inset: 6

    signal dismissed()
    signal launched()

    implicitWidth: 620
    implicitHeight: content.implicitHeight

    onResultsChanged: {
        if (root.results.length > 0)
            root.shownResults = root.results;
    }

    onQueryChanged: Spotlight.prepare(root.query, root.mode)

    onModeChanged: {
        Spotlight.begin(root.mode);
        Spotlight.prepare(root.query, root.mode);
    }

    function activate(entry, alternate): void {
        if (Spotlight.activate(entry, alternate))
            root.launched();
    }

    // Tocar el chip del modo en el que ya estás vuelve a la búsqueda general.
    function toggleMode(mode): void {
        LauncherControl.setMode(root.mode === mode ? "all" : mode);
    }

    Column {
        id: content

        width: parent.width
        spacing: Theme.liquid.gap

        // ── La barra ─────────────────────────────────────────────
        GlassSurface {
            width: parent.width
            height: Theme.liquid.barHeight
            radius: height / 2
            tint: Theme.liquid.field

            // Absorbe los clics para que no lleguen al fondo del overlay,
            // que cerraría Spotlight. El hueco ENTRE las dos piezas no tiene
            // esto: un clic ahí sí cierra, como afuera.
            MouseArea {
                anchors.fill: parent
            }

            SearchField {
                id: search

                anchors.fill: parent
                implicitHeight: Theme.liquid.barHeight
                padding: 20
                fontSize: Theme.liquid.barFont
                contentColor: Theme.liquid.content
                glyph: LauncherCatalog.find(root.mode)?.glyph ?? Theme.systemIcons.search
                placeholder: LauncherCatalog.placeholderFor(root.mode)
                rightInset: scopes.width

                onSearched: value => root.query = value
                onNavigated: delta => list.move(delta)
                onAccepted: root.activate(list.currentEntry, false)
                onAlternateAccepted: root.activate(list.currentEntry, true)
                onTabbed: delta => LauncherControl.cycle(delta)
                onRemoveRequested: Spotlight.remove(list.currentEntry)

                onShortcut: number => {
                    const mode = LauncherCatalog.modeForNumber(number);
                    if (mode !== "")
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

            ScopeButtons {
                id: scopes

                anchors.right: parent.right
                anchors.rightMargin: 13
                anchors.verticalCenter: parent.verticalCenter
                size: 30
                options: LauncherCatalog.modes
                current: root.mode
                contentColor: Theme.liquid.content

                onSelected: value => {
                    root.toggleMode(value);
                    search.focusInput();
                }
            }
        }

        // ── Los resultados ───────────────────────────────────────
        GlassSurface {
            id: panel

            width: parent.width
            height: root.showResults ? Math.min(list.contentHeight, 440) + root.inset * 2 : 0
            opacity: root.showResults ? 1 : 0
            visible: opacity > 0
            tint: Theme.liquid.panel

            // Cae unos píxeles mientras aparece: parece que se desprende de
            // la barra. Translate mueve lo que se ve sin cambiar el espacio
            // que ocupa en la Column.
            transform: Translate {
                y: root.showResults ? 0 : -10

                Behavior on y {
                    NumberAnimation { duration: 320; easing.type: Easing.OutCubic }
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: 350
                    easing.type: Easing.OutExpo
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutQuad
                }
            }

            MouseArea {
                anchors.fill: parent
            }

            ResultList {
                id: list

                anchors.fill: parent
                anchors.margins: root.inset
                model: root.shownResults

                contentColor: Theme.liquid.content
                selectionColor: Theme.liquid.selection
                selectedContent: "#ffffff"
                rowHeight: Theme.liquid.rowHeight
                iconSize: Theme.liquid.iconSize
                titleSize: Theme.font.normal + 1
                tileColor: Theme.liquid.tile
                glyphColor: Theme.liquid.content

                onActivated: entry => root.activate(entry, false)
            }
        }
    }

    Component.onCompleted: {
        Spotlight.begin(root.mode);
        search.focusInput();
    }
}
