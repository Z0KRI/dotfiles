// ORGANISMO: la lista de resultados de Spotlight, con secciones.
//
// La lista es plana, pero dos tipos de fila no se eligen:
//   kind: "header"   el título de una sección ("Aplicaciones", "Archivos")
//   kind: "notice"   un aviso ("El portapapeles está vacío")
//
// ¿Por qué no usar las secciones de ListView (section.property)? Funcionan
// con modelos de Qt que tienen roles; con un arreglo de JavaScript, como el
// nuestro, no hay rol del que leer la sección. Una fila de encabezado más es
// más simple y se ve igual.
//
// La lista sabe moverse y saltarse lo que no se elige. Qué pasa al elegir lo
// decide quien la usa (señal `activated`).

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules

ListView {
    id: root

    signal activated(var entry)

    readonly property var currentEntry: root.selectable(root.currentIndex) ? root.model[root.currentIndex] : null

    clip: true
    spacing: Theme.spacing.xs
    currentIndex: 0
    keyNavigationEnabled: false
    boundsBehavior: Flickable.StopAtBounds

    // Resultados nuevos: la selección vuelve a la primera fila elegible.
    onModelChanged: {
        root.currentIndex = root.nextSelectable(-1, 1);
        root.positionViewAtBeginning();
    }

    function selectable(index) {
        const entry = root.model?.[index];
        return !!entry && entry.kind !== "header" && entry.kind !== "notice";
    }

    // La siguiente fila elegible desde `from` en dirección `delta`, dando la
    // vuelta. -1 si no hay ninguna.
    function nextSelectable(from, delta) {
        const total = root.model?.length ?? 0;
        for (let step = 1; step <= total; step++) {
            const index = ((from + delta * step) % total + total) % total;
            if (root.selectable(index))
                return index;
        }
        return -1;
    }

    function move(delta: int): void {
        const next = root.nextSelectable(root.currentIndex, delta);
        if (next < 0)
            return;

        root.currentIndex = next;

        // Arriba del todo, que se vea también el encabezado de la sección.
        if (root.nextSelectable(-1, 1) === next)
            root.positionViewAtBeginning();
        else
            root.positionViewAtIndex(next, ListView.Contain);
    }

    function activateCurrent(): void {
        if (root.currentEntry)
            root.activated(root.currentEntry);
    }

    delegate: Item {
        id: row

        required property var modelData
        required property int index

        readonly property bool isHeader: row.modelData.kind === "header"
        readonly property bool isNotice: row.modelData.kind === "notice"

        width: ListView.view.width
        height: row.isHeader ? 24 : (row.isNotice ? 56 : result.implicitHeight)

        Label {
            visible: row.isHeader
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacing.md
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 3
            text: row.modelData.title ?? ""
            color: Qt.alpha(Theme.colors.baseContent, 0.55)
            font.pixelSize: Theme.font.small
            font.weight: Font.DemiBold
        }

        Column {
            visible: row.isNotice
            anchors.centerIn: parent
            width: parent.width - Theme.spacing.lg * 2
            spacing: 2

            Label {
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: row.modelData.title ?? ""
                color: Qt.alpha(Theme.colors.baseContent, 0.8)
            }

            Label {
                width: parent.width
                visible: text !== ""
                horizontalAlignment: Text.AlignHCenter
                text: row.modelData.subtitle ?? ""
                color: Qt.alpha(Theme.colors.baseContent, 0.5)
                font.pixelSize: Theme.font.small
                elide: Text.ElideNone
                wrapMode: Text.WordWrap
            }
        }

        ResultRow {
            id: result

            visible: !row.isHeader && !row.isNotice
            anchors.fill: parent
            entry: row.modelData
            selected: row.ListView.isCurrentItem

            onHovered: root.currentIndex = row.index
            onActivated: root.activated(row.modelData)
        }
    }
}
