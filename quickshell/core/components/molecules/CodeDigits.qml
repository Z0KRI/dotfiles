// MOLÉCULA: un código de emparejamiento, un carácter por casilla, como el que
// enseñan iOS y macOS. Con `entered` (0 en adelante) se marcan las casillas
// que ya tecleaste en el aparato; con -1 no se marca ninguna: hay aparatos
// que no avisan cuánto llevas.
//
// Las casillas van en letra monoespaciada a propósito: un 1 y un 8 miden lo
// mismo, y el código no "baila" al leerlo.

import QtQuick
import qs.core.theme
import qs.core.components.atoms

Row {
    id: root

    property string code: ""
    property int entered: -1

    spacing: 6

    Repeater {
        model: root.code.length

        Rectangle {
            id: box

            required property int index

            readonly property bool typed: root.entered > box.index

            width: 34
            height: 44
            radius: 8
            color: box.typed ? Qt.alpha(Theme.colors.accent, 0.16) : Theme.window.control
            border.width: 1
            border.color: box.typed ? Theme.colors.accent : Theme.window.controlBorder

            Behavior on color {
                ColorAnimation { duration: 120 }
            }

            Label {
                anchors.centerIn: parent
                text: root.code.charAt(box.index)
                color: Theme.window.text
                font.family: Theme.font.mono
                font.pixelSize: 22
                font.weight: Font.DemiBold
            }
        }
    }
}
