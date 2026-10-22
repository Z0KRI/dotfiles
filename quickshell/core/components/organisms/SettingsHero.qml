// ORGANISMO: el encabezado de una sección de Ajustes (Wi-Fi, Bluetooth...):
// cuadrito grande, título, una descripción corta y, si hace falta, el
// interruptor principal de la sección a la derecha.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Rectangle {
    id: root

    property string icon: ""
    property color tint: Theme.colors.accent
    property string iconFamily: Theme.font.icon
    property string title: ""
    property string description: ""

    property bool showSwitch: false
    property bool checked: false

    signal toggled()

    width: parent ? parent.width : implicitWidth
    implicitHeight: Math.max(64, texts.implicitHeight + 28)
    radius: Theme.window.radius
    color: Theme.window.group
    border.width: 1
    border.color: Theme.window.groupBorder

    SymbolTile {
        id: tile

        anchors.left: parent.left
        anchors.leftMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        size: 40
        icon: root.icon
        tint: root.tint
        fontFamily: root.iconFamily
    }

    Column {
        id: texts

        anchors.left: tile.right
        anchors.leftMargin: 12
        anchors.right: toggle.visible ? toggle.left : parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        spacing: 3

        Label {
            width: parent.width
            text: root.title
            color: Theme.window.text
            font.pixelSize: Theme.window.fontTitle
            font.weight: Font.Bold
        }

        Label {
            width: parent.width
            visible: root.description !== ""
            text: root.description
            color: Theme.window.textMuted
            font.pixelSize: Theme.window.fontCaption + 1
            wrapMode: Text.WordWrap
        }
    }

    ToggleSwitch {
        id: toggle

        visible: root.showSwitch
        anchors.right: parent.right
        anchors.rightMargin: 14
        anchors.verticalCenter: parent.verticalCenter
        checked: root.checked
        onToggled: root.toggled()
    }
}
