// MOLÉCULA: un chip, la cápsula chica de texto que va sobre el negro del
// marco. Con `icon`, lleva un glifo antes del texto.
//
// Dos estados:
//   normal   blanco tenue de fondo y texto blanco ("Borrar todo", "Apps")
//   chosen   fondo blanco y texto negro: el modo elegido ("Todo" en Spotlight)
//
// Lo usan los encabezados de los paneles (notificaciones, portapapeles) y los
// modos de Spotlight.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Surface {
    id: root

    property string text: ""
    property string icon: ""
    property bool chosen: false

    // Para un aviso destructivo ("¿Borrar todo?"): el texto en rojo.
    property bool warning: false

    property int fontSize: 12

    signal clicked()

    readonly property color ink: root.chosen ? "#000000"
                                 : root.warning ? "#ff7b72"
                                 : Theme.glass.content

    implicitHeight: 26
    implicitWidth: content.implicitWidth + 24
    radius: height / 2

    color: root.chosen ? "#ffffff"
         : hover.hovered ? Theme.glass.tileHover
         : Theme.glass.tile

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
            size: root.fontSize + 1
            color: root.ink
        }

        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: root.text
            color: root.ink
            font.pixelSize: root.fontSize
            font.weight: root.chosen ? Font.DemiBold : Font.Medium
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
