// MOLÉCULA: botón de texto en cápsula de vidrio
// (como "Edit Controls" de macOS). Ej.: "Configuración de red…".
// Con `icon`, lleva un ícono antes del texto.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Surface {
    id: root

    property string text: ""
    property string icon: ""

    signal clicked()

    implicitWidth: content.implicitWidth + 28
    implicitHeight: 30
    radius: height / 2
    border.width: 1
    border.color: Theme.glass.border
    color: hover.hovered ? Theme.glass.tileHover : Theme.glass.tile
    scale: tap.pressed ? 0.95 : 1

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    Behavior on scale {
        NumberAnimation { duration: 120 }
    }

    Row {
        id: content

        anchors.centerIn: parent
        spacing: 6

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: root.icon !== ""
            icon: root.icon
            size: 13
            color: Theme.glass.content
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: Theme.glass.content
            font.pixelSize: Theme.font.small + 1
            font.weight: Font.DemiBold
        }
    }

    HoverHandler {
        id: hover
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        id: tap
        onTapped: root.clicked()
    }
}
