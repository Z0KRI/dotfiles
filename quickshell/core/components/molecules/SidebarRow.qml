// MOLÉCULA: una sección en la barra lateral de Ajustes: cuadrito de color y
// nombre. La elegida se pinta del color de acento con el texto en blanco.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Rectangle {
    id: root

    property string icon: ""
    property color tint: Theme.colors.accent
    property string iconFamily: Theme.font.icon
    property string text: ""
    property bool selected: false

    signal activated()

    width: parent ? parent.width : implicitWidth
    implicitWidth: 200
    implicitHeight: 30
    radius: 7

    // "Apagado" es el mismo color con alfa 0: así la transición no pasa por negro.
    color: {
        if (root.selected)
            return Theme.colors.accent;
        if (hover.hovered)
            return Theme.window.hover;
        return Qt.alpha(Theme.window.hover, 0);
    }

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    SymbolTile {
        id: tile

        anchors.left: parent.left
        anchors.leftMargin: 7
        anchors.verticalCenter: parent.verticalCenter
        size: 20
        icon: root.icon
        tint: root.tint
        fontFamily: root.iconFamily
    }

    Label {
        anchors.left: tile.right
        anchors.leftMargin: 9
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter

        text: root.text
        color: root.selected ? "white" : Theme.window.text
        font.pixelSize: Theme.window.fontBody
        font.weight: root.selected ? Font.Medium : Font.Normal
    }

    HoverHandler {
        id: hover
    }

    TapHandler {
        onTapped: root.activated()
    }
}
