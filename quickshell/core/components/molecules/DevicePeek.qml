// MOLÉCULA: el aviso de una línea de un aparato en la isla plegada: su ícono
// y su nombre a la izquierda; a la derecha, un detalle con ícono (la batería,
// el modo de ruido) o solo texto ("Conectados"). Lo usan los AirPods y los
// teclados.
//
// Las medidas son Theme.island.peek*: las mismas con que PeekWidth calcula
// el ancho de la isla, así el texto cabe justo.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Item {
    id: root

    property string glyph: ""
    property string title: ""
    property string detailIcon: ""
    property string detailText: ""

    // En rojo: la batería se está acabando.
    property bool alert: false
    // Lo de la derecha, tenue: no hay dato todavía ("Conectados").
    property bool dim: false

    readonly property color detailColor: root.alert ? Theme.colors.error
                                         : root.dim ? Theme.island.muted
                                         : Theme.island.fg

    Icon {
        id: glyphIcon

        anchors.left: parent.left
        anchors.leftMargin: Theme.island.peekEdge
        anchors.verticalCenter: parent.verticalCenter

        width: Theme.island.peekGlyph
        icon: root.glyph
        size: Theme.island.peekGlyph
        color: Theme.island.fg
    }

    Label {
        anchors.left: glyphIcon.right
        anchors.leftMargin: Theme.island.peekGap
        anchors.right: detail.left
        anchors.rightMargin: Theme.island.peekSplit
        anchors.verticalCenter: parent.verticalCenter

        text: root.title
        elide: Text.ElideRight
        color: Theme.island.fg
        font.pixelSize: Theme.island.peekText
        font.weight: Font.DemiBold
    }

    Row {
        id: detail

        anchors.right: parent.right
        anchors.rightMargin: Theme.island.peekEdge
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.island.peekIconGap

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.detailIcon !== ""
            width: Theme.island.peekGlyph
            size: Theme.island.peekGlyph
            icon: root.detailIcon
            color: root.detailColor
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: root.detailText
            color: root.detailColor
            font.pixelSize: Theme.island.peekText
        }
    }
}
