// MOLÉCULA: una fila de resultado de Spotlight.
//
// No sabe si es una app, un archivo o algo del portapapeles: lee la forma
// común (domain/launcher/Results) más lo que le agrega la vista:
//
//   entry.title, entry.subtitle   los dos textos
//   entry.icon, entry.image       para ResultIcon
//   entry.glyph                   el glifo de respaldo
//   entry.hint                    lo que hace Enter ("Abrir", "Pegar"…),
//                                 a la derecha, solo en la fila elegida
//   entry.detail                  un dato a la derecha (la fecha de un
//                                 archivo) cuando la fila NO está elegida
//
// Apariencia (de fábrica, la del tema; sobre vidrio, la de Theme.liquid):
//   contentColor     títulos; el subtítulo y lo de la derecha, más tenues
//   selectionColor   el fondo de la fila elegida
//   selectedContent  el texto encima de ese fondo
//   iconSize         el ícono; la fila crece con él
//   tileColor, glyphColor   el cuadrito de respaldo del ícono
//
// Con el subtítulo vacío el título queda centrado solo: una Column no le
// reserva espacio a un hijo invisible.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Surface {
    id: root

    property var entry: null
    property bool selected: false

    property color contentColor: Theme.colors.baseContent
    property color selectionColor: Qt.alpha(Theme.colors.baseContent, 0.1)
    property color selectedContent: root.contentColor
    property int iconSize: 28
    property int titleSize: Theme.font.normal
    property color tileColor: Theme.colors.neutral
    property color glyphColor: Theme.colors.accent

    signal activated()
    // Dónde está el puntero, en coordenadas de la ventana. La fila no decide
    // si eso cuenta como "el usuario la señaló": eso lo decide la lista.
    signal hovered(point scenePosition)

    readonly property color ink: root.selected ? root.selectedContent : root.contentColor
    readonly property string trailingText: root.selected ? (root.entry?.hint ?? "") : (root.entry?.detail ?? "")

    color: root.selected ? root.selectionColor : "transparent"
    radius: Math.round(root.height * 0.28)
    implicitHeight: Math.max(45, root.iconSize + 14)

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        // positionChanged y no entered: entered también llega cuando la FILA
        // se mueve debajo de un mouse quieto (al escribir, al desplazarse).
        onPositionChanged: mouse => root.hovered(mapToItem(null, mouse.x, mouse.y))
        onClicked: root.activated()
    }

    ResultIcon {
        id: icon

        anchors.left: parent.left
        anchors.leftMargin: Theme.spacing.md
        anchors.verticalCenter: parent.verticalCenter
        width: root.iconSize
        height: root.iconSize
        iconName: root.entry?.icon ?? ""
        image: root.entry?.image ?? ""
        glyph: root.entry?.glyph || Theme.systemIcons.squirrel
        tileColor: root.tileColor
        glyphColor: root.glyphColor
    }

    Column {
        anchors.left: icon.right
        anchors.leftMargin: Theme.spacing.md
        // Sin texto a la derecha, el título usa todo el ancho.
        anchors.right: trailing.visible ? trailing.left : parent.right
        anchors.rightMargin: Theme.spacing.md
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Label {
            width: parent.width
            text: root.entry?.title ?? ""
            color: root.ink
            font.pixelSize: root.titleSize
            font.weight: Font.Medium
        }

        Label {
            width: parent.width
            visible: text !== ""
            text: root.entry?.subtitle ?? ""
            color: Qt.alpha(root.ink, 0.62)
            font.pixelSize: Theme.font.small
        }
    }

    Label {
        id: trailing

        anchors.right: parent.right
        anchors.rightMargin: Theme.spacing.md
        anchors.verticalCenter: parent.verticalCenter
        // Sin `width`: un Text sin ancho mide lo que su texto. Escribir
        // width: implicitWidth hace que el ancho dependa de sí mismo, y Qt lo
        // avisa como "binding loop".
        visible: text !== ""
        text: root.trailingText
        color: Qt.alpha(root.ink, root.selected ? 0.85 : 0.5)
        font.pixelSize: Theme.font.small
        elide: Text.ElideNone
    }
}
