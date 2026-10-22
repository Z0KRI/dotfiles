// ORGANISMO: un grupo de Ajustes: el recuadro redondeado con filas dentro.
// Encabezado opcional arriba (en negrita) y una nota gris abajo.
//
// El recuadro es un ClippingRectangle y no un Rectangle: el resaltado de una
// fila al pasar el mouse llega hasta el borde, y sin recorte se saldría por
// las esquinas redondeadas.

import QtQuick
import Quickshell.Widgets
import qs.core.theme
import qs.core.components.atoms

Column {
    id: root

    default property alias content: rows.data

    property string header: ""
    property string footer: ""

    width: parent ? parent.width : implicitWidth
    spacing: 7

    Label {
        visible: root.header !== ""
        leftPadding: 4
        text: root.header
        color: Theme.window.text
        font.pixelSize: Theme.window.fontBody
        font.weight: Font.DemiBold
    }

    ClippingRectangle {
        width: parent.width
        height: rows.implicitHeight
        radius: Theme.window.radius
        color: Theme.window.group
        border.width: 1
        border.color: Theme.window.groupBorder
        contentUnderBorder: true

        Column {
            id: rows
            width: parent.width
        }
    }

    Label {
        visible: root.footer !== ""
        width: parent.width
        leftPadding: 4
        rightPadding: 4
        text: root.footer
        color: Theme.window.textMuted
        font.pixelSize: Theme.window.fontCaption
        wrapMode: Text.WordWrap
    }
}
