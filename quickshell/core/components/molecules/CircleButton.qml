// MOLÉCULA: botoncito redondo con un ícono dentro de un aro, como el "⋯" que
// lleva cada red en Wi-Fi de macOS. Para acciones secundarias de una fila.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Rectangle {
    id: root

    property string icon: ""
    // En vez de ícono, una letra o signo: el "?" de ayuda.
    property string text: ""

    signal clicked()

    implicitWidth: 20
    implicitHeight: 20
    radius: height / 2
    opacity: root.enabled ? 1 : 0.45

    color: tap.pressed ? Theme.window.control : (hover.hovered ? Theme.window.hover : "transparent")
    border.width: 1.5
    border.color: Theme.window.textMuted

    Label {
        anchors.centerIn: parent
        visible: root.text !== ""
        text: root.text
        color: Theme.window.textMuted
        font.pixelSize: 12
        font.weight: Font.DemiBold
    }

    Icon {
        visible: root.icon !== ""
        anchors.centerIn: parent
        icon: root.icon
        size: 12
        color: Theme.window.textMuted
    }

    HoverHandler {
        id: hover
        enabled: root.enabled
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tap
        enabled: root.enabled
        onTapped: root.clicked()
    }
}
