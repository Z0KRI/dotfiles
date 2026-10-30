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
    readonly property list<QtObject> occupants: [notification, airpods, keyboard, volume, brightness, player]

    NotificationOccupant {
        id: notification
    }

    AirPodsOccupant {
        id: airpods
    }

    KeyboardOccupant {
        id: keyboard
    }

    VolumeOccupant {
        id: volume
    }

    BrightnessOccupant {
        id: brightness
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
    //
    // Un ocupante apagado en Ajustes (volumen, brillo, música, AirPods o
    // teclado) no compite: sigue vivo y sabiendo su estado, solo que no se le
    // da la isla.
    readonly property var winner: {
        let best = null
        const list = root.occupants
        for (let i = 0; i < list.length; ++i) {
            const candidate = list[i]
            if (!candidate.active || !IslandOccupants.allows(candidate.name))
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

    // ── las ventanas ──────────────────────────────────────────────
    //
    // Una por pantalla, pero solo existe para el compositor (mapeada, con sus
    // búferes) la que está dibujando la isla, y solo mientras dibuja algo. Sin
    // ocupante no hay ventana: la isla vacía no gasta memoria.
    //
    // Miden lo justo para la isla desplegada, con aire para el rebote de la
    // animación (OutBack se pasa un poco del tamaño final).
    readonly property int frameWidth: Theme.island.openWidth + 96
    readonly property int frameHeight: Theme.island.openHeight + 64

    Variants {
        model: Quickshell.screens

        IslandWindow {
            id: window

            required property var modelData
            screen: window.modelData

            readonly property bool mine: IslandState.screenName === window.modelData.name

            // Cuando la isla se va a otro monitor, esta se queda lo que dura
            // la salida, para que se vea irse en vez de desaparecer de golpe.
            readonly property bool drawing: window.mine || linger.running

            onMineChanged: {
                if (!window.mine)
                    linger.restart();
            }

            Timer {
                id: linger
                interval: Theme.island.exitDuration + 80
            }

            visible: window.drawing && root.drawn !== null

            implicitWidth: root.frameWidth
            implicitHeight: root.frameHeight

            // Solo la ventana que enseña la island recibe el ratón, y solo en
            // la zona.
            maskItem: IslandState.open && window.mine ? surface.body : null

            IslandSurface {
                id: surface

                anchors.fill: parent

                // Las ventanas que no dibujan no cargan la vista: si no, el
                // visualizador de la música seguiría animándose en todas.
                occupant: window.drawing ? root.drawn : null
                shown: IslandState.open && window.mine
                owner: window.mine

                // El mismo cálculo que hace el compositor para centrarla.
                originX: Math.round((window.modelData.width - root.frameWidth) / 2)
            }
        }
    }
}