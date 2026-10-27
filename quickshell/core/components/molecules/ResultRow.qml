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
// Con el subtítulo vacío el título queda centrado solo: una Column no le
// reserva espacio a un hijo invisible.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Surface {
    id: root

    property var entry: null
    property bool selected: false

    signal activated()
    signal hovered()

    readonly property string trailingText: root.selected ? (root.entry?.hint ?? "") : (root.entry?.detail ?? "")

    color: root.selected ? Qt.alpha(Theme.colors.baseContent, 0.1) : "transparent"
    radius: Theme.radius.md
    implicitHeight: 45

    MouseArea {
        anchors.fill: parent
        hoverEnabled: true
        onEntered: root.hovered()
        onClicked: root.activated()
    }

    ResultIcon {
        id: icon

        anchors.left: parent.left
        anchors.leftMargin: Theme.spacing.md
        anchors.verticalCenter: parent.verticalCenter
        iconName: root.entry?.icon ?? ""
        image: root.entry?.image ?? ""
        glyph: root.entry?.glyph || Theme.systemIcons.squirrel
    }

    Column {
        anchors.left: icon.right
        anchors.leftMargin: Theme.spacing.md + Theme.spacing.sm
        // Sin texto a la derecha, el título usa todo el ancho.
        anchors.right: trailing.visible ? trailing.left : parent.right
        anchors.rightMargin: Theme.spacing.md
        anchors.verticalCenter: parent.verticalCenter
        spacing: 1

        Label {
            width: parent.width
            text: root.entry?.title ?? ""
            font.pixelSize: Theme.font.normal
        }

        Label {
            width: parent.width
            visible: text !== ""
            text: root.entry?.subtitle ?? ""
            color: Qt.alpha(Theme.colors.baseContent, 0.6)
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
        color: Qt.alpha(Theme.colors.baseContent, root.selected ? 0.75 : 0.5)
        font.pixelSize: Theme.font.small
        elide: Text.ElideNone
    }
}
