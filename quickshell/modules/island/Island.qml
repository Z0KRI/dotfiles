// La feature. Los ocupantes viven aquí una sola vez, el árbitro decide quién
// manda, y hay una ventana por pantalla aunque solo una la enseñe.
//
// El árbitro vive en el módulo y no en `domain` porque necesita la lista de
// ocupantes, y los ocupantes son hijos declarados aquí. Un singleton de dominio
// que fuera a buscarlos invertiría la regla de dependencias.

import QtQuick
import Quickshell
import qs.core.theme
import qs.core.components.templates
import qs.domain.island
import qs.modules.island.occupants

Scope {
    id: root

    // Añadir un ocupante es declararlo y sumarlo a esta lista.
    readonly property list<QtObject> occupants: [notification, volume, player]

    NotificationOccupant {
        id: notification
    }

    VolumeOccupant {
        id: volume
    }

    PlayerOccupant {
        id: player
    }

    // ── el árbitro ────────────────────────────────────────────────
    // Gana el de mayor prioridad entre los que quieren la island. Si nadie la
    // quiere, `null` — y ese es el caso normal, no la excepción.
    //
    // Usa `effectivePriority` y no `priority`: un ocupante desplegado se sube
    // solo por encima de todos mientras lo estés usando.
    readonly property var winner: {
        let best = null
        const list = root.occupants
        for (let i = 0; i < list.length; ++i) {
            const candidate = list[i]
            if (!candidate.active)
                continue
            if (best === null
                    || candidate.effectivePriority > best.effectivePriority)
                best = candidate
        }
        return best
    }

    // El que se DIBUJA va por detrás del que manda: cuando el ganador se va,
    // este se queda hasta que acabe la animación de salida. Sin esto la island
    // se iría vacía, porque su contenido desaparecería de golpe.
    property var drawn: null

    // Quien pierde la island no se queda desplegado a escondidas, esperando a
    // reaparecer del tamaño de una tarjeta.
    function collapseLosers(): void {
        const list = root.occupants;
        for (let i = 0; i < list.length; ++i) {
            if (list[i] !== root.winner)
                list[i].collapse();
        }
    }

    onWinnerChanged: {
        root.collapseLosers();

        if (root.winner) {
            clear.stop();
            root.drawn = root.winner;
            IslandState.occupant = root.winner.name;
            return;
        }

        IslandState.occupant = "";
        IslandState.hovered = false;
        clear.restart();
    }

    Timer {
        id: clear
        interval: Theme.island.exitDuration + 80
        onTriggered: root.drawn = null
    }

    Variants {
        model: Quickshell.screens

        IslandWindow {
            id: window

            required property var modelData
            screen: window.modelData

            readonly property bool mine: IslandState.screenName === window.modelData.name

            // TEMPORAL — era `surface.body`. Con la superficie entera, la
            // island se queda con TODO el ratón de la pantalla mientras esté
            // visible: no lo dejes puesto. Solo sirve para saber si el hover
            // falla por la región de entrada o por la lógica de despliegue.
            maskItem: IslandState.open && window.mine ? surface.body : null

            IslandSurface {
                id: surface

                anchors.fill: parent

                occupant: root.drawn
                shown: IslandState.open && window.mine
            }
        }
    }
}