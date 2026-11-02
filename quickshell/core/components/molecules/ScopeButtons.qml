// MOLÉCULA: los chips de modo, uno elegido a la vez. Son los de Spotlight
// (Todo, Apps, Archivos), pero no saben nada de Spotlight: reciben opciones y
// avisan cuál tocaste.
//
// `options` es una lista de objetos con value, glyph y label. El elegido va
// en blanco con texto negro; los demás, en el blanco tenue del marco (ver
// ChipButton).
//
// (En este comentario no van llaves: el escáner de Quickshell deja de leer
// los import en la primera línea que tenga una.)

import QtQuick
import qs.core.theme

Row {
    id: root

    property var options: []
    property var current

    property int chipHeight: 28

    signal selected(var value)

    spacing: Theme.spacing.sm

    Repeater {
        model: root.options

        ChipButton {
            id: chip

            required property var modelData

            height: root.chipHeight
            icon: chip.modelData.glyph ?? ""
            text: chip.modelData.label ?? ""
            chosen: chip.modelData.value === root.current

            onClicked: root.selected(chip.modelData.value)
        }
    }
}
