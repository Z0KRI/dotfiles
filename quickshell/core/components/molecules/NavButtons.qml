// MOLÉCULA: los botones ‹ › de la barra de herramientas (atrás / adelante),
// juntos en una cápsula como en Golden Gate.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Rectangle {
    id: root

    property bool canGoBack: false
    property bool canGoForward: false

    signal back()
    signal forward()

    implicitWidth: 64
    implicitHeight: 28
    radius: height / 2
    color: Theme.window.control

    component Arrow: Item {
        id: arrow

        property string glyph: ""
        property bool usable: true

        signal activated()

        width: root.width / 2
        height: root.height

        Rectangle {
            anchors.fill: parent
            anchors.margins: 2
            radius: height / 2
            color: arrow.usable && hover.hovered ? Theme.window.hover : "transparent"
        }

        Icon {
            anchors.centerIn: parent
            icon: arrow.glyph
            size: 14
            color: Theme.window.text
            opacity: arrow.usable ? 0.85 : 0.25
        }

        HoverHandler {
            id: hover
            enabled: arrow.usable
        }

        TapHandler {
            enabled: arrow.usable
            onTapped: arrow.activated()
        }
    }

    Row {
        anchors.fill: parent

        Arrow {
            glyph: Theme.systemIcons.chevronLeft
            usable: root.canGoBack
            onActivated: root.back()
        }

        Arrow {
            glyph: Theme.systemIcons.chevronRight
            usable: root.canGoForward
            onActivated: root.forward()
        }
    }
}
