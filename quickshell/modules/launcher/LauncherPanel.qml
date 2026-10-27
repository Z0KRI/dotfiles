// El panel de Spotlight: la barra con los chips de modo y la lista de
// resultados. Es el único que tiene estado de pantalla (lo que llevas
// escrito); el modo vive en LauncherControl porque también lo cambian los
// atajos de Hyprland.
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
import Quickshell.Widgets
import qs.core.theme
import qs.core.components.molecules
import qs.core.components.organisms
import qs.domain.launcher

ClippingRectangle {
    id: root

    property string query: ""
    readonly property string mode: LauncherControl.mode

    readonly property var results: Spotlight.results(root.query, root.mode).map(LauncherCatalog.decorate)
    readonly property bool showResults: root.results.length > 0

    // Lo que la lista muestra. Solo se actualiza cuando HAY algo que mostrar,
    // así al ocultarse se desvanece con los últimos resultados, no con otros.
    property var shownResults: []

    signal dismissed()
    signal launched()

    implicitWidth: 580
    implicitHeight: content.implicitHeight + Theme.spacing.sm

    color: Theme.glass.menu
    radius: Theme.radius.lg

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

    // Absorbe los clics para que no lleguen al fondo del overlay.
    MouseArea {
        anchors.fill: parent
    }

    Column {
        id: content

        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.margins: Theme.spacing.xs
        spacing: Theme.spacing.sm

        Item {
            width: parent.width
            height: search.implicitHeight

            SearchField {
                id: search

                anchors.fill: parent
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
                anchors.rightMargin: Theme.spacing.sm
                anchors.verticalCenter: parent.verticalCenter
                options: LauncherCatalog.modes
                current: root.mode

                onSelected: value => {
                    root.toggleMode(value);
                    search.focusInput();
                }
            }
        }

        ResultList {
            id: list

            width: parent.width
            height: root.showResults ? Math.min(contentHeight, 420) : 0
            opacity: root.showResults ? 1 : 0
            visible: opacity > 0
            model: root.shownResults

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

            onActivated: entry => root.activate(entry, false)
        }
    }

    Component.onCompleted: {
        Spotlight.begin(root.mode);
        search.focusInput();
    }
}
