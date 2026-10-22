// MOLÉCULA: una miniatura de "Claro / Oscuro / Automático" de Apariencia:
// una ventanita dibujada con su barra lateral, y el nombre debajo.
// `look`: "light", "dark" o "auto". Automático se dibuja mitad clara y
// mitad oscura: la misma ventanita dos veces, la oscura recortada a la mitad.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Item {
    id: root

    property string look: "light"
    property string text: ""
    property bool selected: false

    signal activated()

    implicitWidth: 76
    implicitHeight: thumb.height + 6 + label.implicitHeight

    component Mini: Rectangle {
        id: mini

        property bool darkLook: false

        radius: 6
        color: mini.darkLook ? "#2b2b2e" : "#f2f2f4"

        Rectangle {
            width: parent.width * 0.32
            height: parent.height
            radius: parent.radius
            color: mini.darkLook ? "#3a3a3d" : "#dedee2"
        }

        Rectangle {
            x: parent.width * 0.42
            y: parent.height * 0.22
            width: parent.width * 0.48
            height: 4
            radius: 2
            color: Theme.colors.accent
        }

        Rectangle {
            x: parent.width * 0.42
            y: parent.height * 0.22 + 9
            width: parent.width * 0.34
            height: 4
            radius: 2
            color: mini.darkLook ? "#5a5a5e" : "#c8c8cc"
        }
    }

    Rectangle {
        id: thumb

        anchors.horizontalCenter: parent.horizontalCenter
        width: 72
        height: 48
        radius: 9
        color: "transparent"
        border.width: 2.5
        border.color: root.selected ? Theme.colors.accent : "transparent"

        Item {
            anchors.fill: parent
            anchors.margins: 4
            clip: true

            Mini {
                anchors.fill: parent
                darkLook: root.look === "dark"
            }

            // Automático: la mitad derecha oscura.
            Item {
                visible: root.look === "auto"
                x: parent.width / 2
                width: parent.width / 2
                height: parent.height
                clip: true

                Mini {
                    x: -parent.x
                    width: parent.parent.width
                    height: parent.height
                    darkLook: true
                }
            }
        }
    }

    Label {
        id: label

        anchors.top: thumb.bottom
        anchors.topMargin: 6
        anchors.horizontalCenter: parent.horizontalCenter
        text: root.text
        color: Theme.window.text
        font.pixelSize: Theme.window.fontCaption + 1
        font.weight: root.selected ? Font.DemiBold : Font.Normal
    }

    HoverHandler {
        cursorShape: Qt.PointingHandCursor
    }

    TapHandler {
        onTapped: root.activated()
    }
}
