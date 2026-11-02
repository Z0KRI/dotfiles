// Lo que va dentro del panel del portapapeles (la esquina de abajo a la
// derecha):
//
//   arriba     "Portapapeles", Borrar y la ×
//   debajo     el buscador
//   el resto   el historial, lo más nuevo arriba
//
// Cada fila dice qué es (Código, Ruta, Imagen PNG…) y las imágenes llevan su
// miniatura. El texto de código, rutas y comandos va en monoespaciada.
//
// Teclas:
//   ↑ ↓            moverse
//   Enter          pegar en la ventana donde estabas (o solo copiar, según
//                  Ajustes › Spotlight › Portapapeles)
//   Ctrl + Enter   solo copiar
//   Shift + Supr   borrar esa entrada
//   Esc            borra lo escrito; con el campo vacío, cierra

import QtQuick
import Quickshell.Widgets
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.domain.clipboard

Item {
    id: root

    property string query: ""

    readonly property var entries: SearchClipboard.find(root.query, 200)

    signal dismissed()

    readonly property int inset: Theme.frame.inset

    readonly property var glyphs: ({
        image: Theme.systemIcons.launcher.image,
        link: Theme.systemIcons.launcher.link,
        path: Theme.systemIcons.launcher.files,
        command: Theme.systemIcons.launcher.command,
        code: Theme.systemIcons.launcher.code,
        text: Theme.systemIcons.launcher.text
    })

    // Lo que dice el panel cuando no hay filas.
    readonly property string notice: {
        if (!SearchClipboard.available)
            return "cliphist no está instalado.\nInstálalo con ./install.sh.";
        if (!SearchClipboard.loaded)
            return "";
        if (SearchClipboard.empty)
            return "El portapapeles está vacío.\nLo que copies aparece aquí.";
        return root.entries.length === 0 ? "Nada coincide." : "";
    }

    function choose(entry, copyOnly): void {
        if (!entry)
            return;

        // Primero se cierra (el teclado vuelve a tu ventana) y después se
        // pega: ClipboardRepository espera un momento antes de mandar Ctrl + V.
        root.dismissed();
        SearchClipboard.choose(entry.target, copyOnly);
    }

    function move(delta): void {
        if (list.count === 0)
            return;
        list.currentIndex = Math.max(0, Math.min(list.count - 1, list.currentIndex + delta));
        list.positionViewAtIndex(list.currentIndex, ListView.Contain);
    }

    // ── Arriba ──
    Item {
        id: header

        x: root.inset
        y: root.inset
        width: parent.width - root.inset * 2
        height: 26

        Label {
            anchors.left: parent.left
            anchors.leftMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            text: "Portapapeles"
            color: Theme.glass.content
            font.pixelSize: Theme.font.large
            font.weight: Font.Bold
        }

        Row {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            spacing: 6

            // Borrar todo el historial no tiene vuelta atrás: el primer clic
            // pregunta y el segundo (dentro de 3 s) borra.
            ChipButton {
                id: wipe

                property bool asking: false

                visible: SearchClipboard.available && !SearchClipboard.empty
                text: wipe.asking ? "¿Borrar todo?" : "Borrar"
                warning: wipe.asking

                onClicked: {
                    if (wipe.asking) {
                        wipe.asking = false;
                        SearchClipboard.clear();
                    } else {
                        wipe.asking = true;
                        cancelWipe.restart();
                    }
                }

                Timer {
                    id: cancelWipe
                    interval: 3000
                    onTriggered: wipe.asking = false
                }
            }

            Rectangle {
                width: 26
                height: 26
                radius: 13
                color: closeHover.hovered ? Theme.glass.tileHover : Theme.glass.tile

                Icon {
                    anchors.centerIn: parent
                    icon: Theme.systemIcons.xMark
                    size: 12
                    color: Theme.glass.content
                }

                HoverHandler {
                    id: closeHover
                    cursorShape: Qt.PointingHandCursor
                }

                MouseArea {
                    anchors.fill: parent
                    onClicked: root.dismissed()
                }
            }
        }
    }

    // ── El buscador ──
    SearchField {
        id: search

        x: root.inset
        anchors.top: header.bottom
        anchors.topMargin: 10
        width: parent.width - root.inset * 2
        height: 34
        implicitHeight: 34

        radius: 17
        color: Qt.rgba(1, 1, 1, 0.08)
        padding: 12
        fontSize: 13
        contentColor: Theme.glass.content
        glyph: Theme.systemIcons.search
        placeholder: "Buscar en el portapapeles"

        onSearched: value => root.query = value
        onNavigated: delta => root.move(delta)
        onAccepted: root.choose(root.entries[list.currentIndex], false)
        onAlternateAccepted: root.choose(root.entries[list.currentIndex], true)
        onRemoveRequested: SearchClipboard.remove(root.entries[list.currentIndex]?.target)

        onDismissed: {
            if (search.text !== "")
                search.clear();
            else
                root.dismissed();
        }
    }

    // ── El historial ──
    ListView {
        id: list

        x: root.inset
        anchors.top: search.bottom
        anchors.topMargin: 10
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.inset
        width: parent.width - root.inset * 2

        clip: true
        spacing: 6
        boundsBehavior: Flickable.StopAtBounds
        keyNavigationEnabled: false

        model: root.entries

        // Lista nueva (escribiste, se borró una): la selección vuelve arriba.
        onModelChanged: list.currentIndex = 0

        delegate: Rectangle {
            id: row

            required property var modelData
            required property int index

            readonly property bool selected: row.ListView.isCurrentItem
            readonly property bool isImage: row.modelData.kind === "image"
            readonly property bool hasThumb: row.isImage && row.modelData.thumb !== ""

            width: ListView.view.width
            height: Math.max(row.hasThumb ? 40 : 28, texts.implicitHeight) + 16
            radius: 14
            color: row.selected ? Qt.rgba(1, 1, 1, 0.14) : "transparent"

            MouseArea {
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                // positionChanged y no entered: entered también llega cuando
                // la fila se mueve debajo de un mouse quieto.
                onPositionChanged: list.currentIndex = row.index
                onClicked: root.choose(row.modelData, false)
            }

            // La miniatura, o el tipo en un cuadrito.
            Item {
                id: lead

                x: 10
                anchors.verticalCenter: parent.verticalCenter
                width: row.hasThumb ? 64 : 28
                height: row.hasThumb ? 40 : 28

                Rectangle {
                    anchors.fill: parent
                    visible: !row.hasThumb
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.14)

                    Icon {
                        anchors.centerIn: parent
                        icon: root.glyphs[row.modelData.kind] ?? Theme.systemIcons.launcher.text
                        size: 14
                        color: Theme.glass.content
                    }
                }

                // Con las esquinas redondas: ClippingRectangle recorta lo
                // que lleva dentro a su radio (un Rectangle no recorta).
                ClippingRectangle {
                    anchors.fill: parent
                    visible: row.hasThumb
                    radius: 8
                    color: Qt.rgba(1, 1, 1, 0.14)

                    Image {
                        anchors.fill: parent
                        source: row.hasThumb ? row.modelData.thumb : ""
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        smooth: true

                        // Solo lo que se ve: 64 × 40 al doble de densidad,
                        // no la captura entera de 4 MB en memoria.
                        sourceSize.width: 128
                        sourceSize.height: 80
                    }
                }
            }

            Column {
                id: texts

                anchors.left: lead.right
                anchors.leftMargin: 10
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 2

                Label {
                    width: parent.width
                    text: row.modelData.text
                    color: "#f2f2f7"
                    font.family: row.modelData.mono ? Theme.font.mono : Theme.font.ui
                    font.pixelSize: 12
                    font.weight: row.isImage ? Font.Medium : Font.Normal
                    wrapMode: Text.WrapAnywhere
                    maximumLineCount: 2
                    elide: Text.ElideRight
                }

                Label {
                    width: parent.width
                    text: row.modelData.label
                    color: Theme.glass.contentMuted
                    font.pixelSize: 11
                }
            }
        }
    }

    Label {
        anchors.centerIn: list
        width: list.width - 40
        visible: root.notice !== ""
        text: root.notice
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        color: Theme.glass.contentMuted
        font.pixelSize: 13
    }

    Component.onCompleted: search.focusInput()
}
