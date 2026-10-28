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
//
// La apariencia la recibe de quien la usa y la reparte a cada fila: la lista
// no sabe si está sobre vidrio o sobre un fondo claro.

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules

ListView {
    id: root

    signal activated(var entry)

    property color contentColor: Theme.colors.baseContent
    property color selectionColor: Qt.alpha(Theme.colors.baseContent, 0.1)
    property color selectedContent: root.contentColor
    property int rowHeight: 45
    property int iconSize: 28
    property int titleSize: Theme.font.normal
    property color tileColor: Theme.colors.neutral
    property color glyphColor: Theme.colors.accent

    // Dónde estaba el puntero la última vez, en coordenadas de la ventana.
    // (-1, -1): todavía no se sabe.
    property point pointer: Qt.point(-1, -1)

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

    // El mouse elige una fila solo si se MOVIÓ en la pantalla.
    //
    // Cuando aparecen resultados nuevos (escribiste una letra) o la lista se
    // desplaza con las flechas, las filas pasan por debajo de un mouse que
    // no se movió, y Qt les avisa igual. Sin esta regla, la fila que quedara
    // debajo del puntero te robaría la selección mientras navegas con el
    // teclado. La primera vez solo se anota dónde está el mouse: no hay con
    // qué comparar.
    function pointed(index, scenePosition): void {
        const moved = scenePosition.x !== root.pointer.x || scenePosition.y !== root.pointer.y;
        const known = root.pointer.x >= 0;

        root.pointer = scenePosition;

        if (moved && known && root.selectable(index))
            root.currentIndex = index;
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
        height: row.isHeader ? 26 : (row.isNotice ? 60 : root.rowHeight)

        Label {
            visible: row.isHeader
            anchors.left: parent.left
            anchors.leftMargin: Theme.spacing.md
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 4
            text: row.modelData.title ?? ""
            color: Qt.alpha(root.contentColor, 0.55)
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
                color: Qt.alpha(root.contentColor, 0.85)
            }

            Label {
                width: parent.width
                visible: text !== ""
                horizontalAlignment: Text.AlignHCenter
                text: row.modelData.subtitle ?? ""
                color: Qt.alpha(root.contentColor, 0.55)
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

            contentColor: root.contentColor
            selectionColor: root.selectionColor
            selectedContent: root.selectedContent
            iconSize: root.iconSize
            titleSize: root.titleSize
            tileColor: root.tileColor
            glyphColor: root.glyphColor

            onHovered: scenePosition => root.pointed(row.index, scenePosition)
            onActivated: root.activated(row.modelData)
        }
    }

    // Barra de desplazamiento fina, como la de Ajustes: solo se ve mientras
    // la lista se mueve.
    //
    // `parent: root` no sobra. Lo que se declara dentro de un ListView (es un
    // Flickable) va a su contenido, el que se desplaza: sin esta línea la
    // barra se iría para arriba con las filas. Con ella cuelga del ListView
    // mismo y se queda quieta.
    Rectangle {
        parent: root
        z: 1
        visible: root.contentHeight > root.height
        x: root.width - width - 3
        y: root.visibleArea.yPosition * root.height
        width: 4
        height: Math.max(24, root.visibleArea.heightRatio * root.height)
        radius: 2
        color: root.contentColor
        opacity: root.moving ? 0.45 : 0

        Behavior on opacity {
            NumberAnimation { duration: root.moving ? 80 : 600 }
        }
    }
}
