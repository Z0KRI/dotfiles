// El cuerpo de la island: la silueta, la vista del ocupante y las animaciones
// que lo son todo — el tamaño, la entrada desde el borde y el relevo de una
// vista por otra.
//
// Ocupa la ventana entera para poder centrar el cuerpo, pero lo único que
// recibe el ratón es `body`.

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.domain.island

Item {
    id: root

    // El ocupante que se DIBUJA. Va un poco por detrás del que manda, para que
    // la salida tenga algo que dibujar mientras se va.
    property var occupant: null

    // ¿está dentro de la pantalla?
    property bool shown: false

    readonly property bool expanded: root.occupant ? root.occupant.isExpanded : false

    // Lo que la feature usa de máscara.
    readonly property Item body: viewport

    // ── el hueco que la barra tiene que respetar ──────────────────
    //
    // Se calcula con el tamaño de DESTINO y no con el animado: si siguiera la
    // animación, la máscara de la barra se recalcularía en cada fotograma para
    // nada. Un poco más grande que el cuerpo, para que los bordes no se peleen
    // por el mismo píxel.
    readonly property rect targetRect: {
        if (!root.shown || !root.occupant)
            return Qt.rect(0, 0, 0, 0)

        const margin = 6
        const w = root.occupant.currentWidth + margin * 2
        const h = root.occupant.currentHeight + margin

        return Qt.rect(Math.round((root.width - w) / 2), 0, w, h)
    }

    onTargetRectChanged: IslandState.bodyRect = root.targetRect

    IslandShape {
        id: shape

        x: Math.round((root.width - width) / 2)

        // Escondida, se va por arriba fuera de la pantalla. Este es el estado
        // POR DEFECTO de esta island: no hay píldora de reposo, así que nadie
        // la ocupa la mayor parte del tiempo.
        y: root.shown ? 0 : -(height + 8)

        bodyWidth: root.occupant ? root.occupant.currentWidth
                                 : Theme.island.minWidth
        bodyHeight: root.occupant ? root.occupant.currentHeight
                                  : Theme.island.minHeight

        wing: Theme.island.wing
        fill: Theme.island.bg

        // Desplegada es una tarjeta, no una píldora: el redondeo crece con ella.
        cornerRadius: root.expanded ? Theme.island.expandedRadius
                                    : Theme.island.radius

        opacity: root.shown ? 1 : 0

        Behavior on y {
            NumberAnimation {
                duration: root.shown ? Theme.island.enterDuration
                                     : Theme.island.exitDuration
                easing.type: root.shown ? Easing.OutBack : Easing.InQuad
                easing.overshoot: Theme.island.enterOvershoot
            }
        }

        Behavior on opacity {
            NumberAnimation {
                duration: Theme.island.exitDuration
            }
        }

        // ── el estirón ────────────────────────────────────────────
        //
        // Las tres se mueven con la MISMA duración y la MISMA curva. Que el
        // ancho, el alto y el redondeo lleguen a destiempo es lo que hace que
        // una island parezca tres animaciones en vez de un objeto.
        Behavior on bodyWidth {
            NumberAnimation {
                duration: Theme.island.sizeDuration
                easing.type: Easing.OutBack
                easing.overshoot: Theme.island.sizeOvershoot
            }
        }

        Behavior on bodyHeight {
            NumberAnimation {
                duration: Theme.island.sizeDuration
                easing.type: Easing.OutBack
                easing.overshoot: Theme.island.sizeOvershoot
            }
        }

        Behavior on cornerRadius {
            NumberAnimation {
                duration: Theme.island.sizeDuration
                easing.type: Easing.OutBack
                easing.overshoot: Theme.island.sizeOvershoot
            }
        }

        // El cuerpo sin las alas: aquí dentro va la vista y aquí se recibe el
        // ratón. Recortado, para que una vista que todavía no ha terminado de
        // encogerse no se salga por los lados.
        Item {
            id: viewport

            x: shape.wing
            y: 0
            width: shape.bodyWidth
            height: shape.bodyHeight
            clip: true

            // El orden importa: este va ANTES del Loader para quedar DEBAJO.
            // Así los botones de transporte se llevan sus clics y aquí solo
            // cae lo que toca el fondo de la island. El hover sigue llegando
            // porque los botones no tienen `hoverEnabled`.
            MouseArea {
                anchors.fill: parent
                hoverEnabled: true

                cursorShape: root.occupant && root.occupant.expandable
                    ? Qt.PointingHandCursor
                    : Qt.ArrowCursor

                onEntered: IslandState.hovered = true
                onExited: IslandState.hovered = false

                // El clic solo sirve para quien NO se abre al pasar el ratón.
                onClicked: {
                    if (root.occupant && !root.occupant.expandOnHover)
                        root.occupant.toggleExpanded();
                }
            }

            // El relevo de una vista por otra. Sin esto, el contenido nuevo
            // aparece entero y de golpe mientras la silueta todavía está
            // creciendo, y eso es justo lo que delata que son dos cosas.
            Loader {
                id: content

                anchors.fill: parent
                sourceComponent: root.occupant ? root.occupant.currentView : null

                opacity: 0
                scale: 0.94

                onSourceComponentChanged: {
                    content.opacity = 0;
                    content.scale = 0.94;
                }

                onLoaded: {
                    content.opacity = 1;
                    content.scale = 1;
                }

                Behavior on opacity {
                    NumberAnimation {
                        duration: Theme.island.contentDuration
                        easing.type: Easing.OutCubic
                    }
                }

                Behavior on scale {
                    NumberAnimation {
                        duration: Theme.island.contentDuration
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }
}