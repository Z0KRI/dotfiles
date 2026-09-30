import QtQuick
import Quickshell
import qs.core.components.atoms
import qs.core.components.templates
import qs.domain.desktop

Scope {
    id: root

    Variants {
        model: Quickshell.screens

        BarWindow {
            id: window

            required property var modelData
            screen: window.modelData

            autoHide: BarVisibility.autoHide(window.modelData)
            reserveSpace: BarVisibility.reserveSpace(window.modelData)
            aboveFullscreen: BarVisibility.aboveFullscreen(window.modelData)
            solid: BarVisibility.solid(window.modelData)

            keepRevealed: barContent.popupOpen

            BarContent {
                id: barContent

                width: parent.width
                screen: window.modelData
                solid: window.solid
            }
        }
    }
}