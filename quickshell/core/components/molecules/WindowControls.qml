// MOLÉCULA: los tres botones de ventana de macOS (cerrar, minimizar, zoom).
// Al pasar el mouse por el grupo aparecen sus símbolos, como en macOS.
//
// Uno que no se puede usar se pinta gris y no reacciona. En Ajustes son dos:
// Hyprland no tiene "minimizar", y la ventana de Ajustes no se agranda (el
// zoom también está apagado en los Ajustes del Sistema de macOS).

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Row {
    id: root

    property bool canMinimize: false
    property bool canZoom: false

    signal closeClicked()
    signal minimizeClicked()
    signal zoomClicked()

    spacing: 8

    HoverHandler {
        id: groupHover
    }

    component Light: Rectangle {
        id: light

        property color tint
        property bool usable: true
        property string glyph: ""

        signal activated()

        width: 12
        height: 12
        radius: 6
        color: light.usable ? light.tint : Theme.window.buttonOff
        border.width: 1
        border.color: Qt.rgba(0, 0, 0, light.usable ? 0.12 : 0.04)

        // Más oscuro mientras lo presionas.
        Rectangle {
            anchors.fill: parent
            radius: parent.radius
            color: Qt.rgba(0, 0, 0, tap.pressed ? 0.2 : 0)
        }

        Icon {
            anchors.centerIn: parent
            visible: light.usable && groupHover.hovered
            icon: light.glyph
            size: 9
            color: Qt.rgba(0, 0, 0, 0.6)
        }

        TapHandler {
            id: tap
            enabled: light.usable
            onTapped: light.activated()
        }
    }

    Light {
        tint: Theme.window.closeButton
        glyph: Theme.systemIcons.xMark
        onActivated: root.closeClicked()
    }

    Light {
        tint: Theme.window.minimizeButton
        glyph: Theme.systemIcons.minus
        usable: root.canMinimize
        onActivated: root.minimizeClicked()
    }

    Light {
        tint: Theme.window.zoomButton
        glyph: Theme.systemIcons.plus
        usable: root.canZoom
        onActivated: root.zoomClicked()
    }
}
