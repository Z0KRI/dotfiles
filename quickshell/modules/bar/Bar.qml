// La barra de menús: una por monitor. Cuándo se esconde, si empuja ventanas
// o si se ve sólida lo decide BarVisibility; aquí solo se conecta.

import QtQuick
import Quickshell
import qs.core.components.templates
import qs.domain.desktop
import qs.domain.island

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

            // ── El hueco de la isla ───────────────────────────────
            //
            // La isla vive en este mismo borde y, en pantalla completa, esta
            // barra sube a la capa overlay y le queda por encima. Restarle su
            // hueco es lo que hace que el ratón le llegue sin depender de quién
            // quede encima ni del orden en que se construyeron las superficies.
            //
            // Solo en la pantalla donde la isla se está dibujando: hay una
            // barra por monitor y un solo rectángulo, así que sin esta pregunta
            // la otra barra se agujerearía el centro para nada.
            readonly property bool islandHere: IslandState.open
                && IslandState.screenName === window.modelData.name

            cutout: window.islandHere ? IslandState.bodyRect : Qt.rect(0, 0, 0, 0)

            BarContent {
                id: barContent

                width: parent.width
                screen: window.modelData
                solid: window.solid
            }
        }
    }
}
