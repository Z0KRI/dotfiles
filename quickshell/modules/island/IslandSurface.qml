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

    // Lo que la feature usa de máscara: la zona, no la silueta.
    readonly property Item body: hitArea

    // Cuánto se estira la zona sensible por debajo del notch. El notch cerrado
    // mide 32 px pegado al borde superior, que es un blanco pequeño; este
    // colchón hace que acercarse por abajo también cuente.
    readonly property int hitPadding: 12

    // ── el hueco que la barra tiene que respetar ──────────────────
    //
    // Se calcula con el tamaño de DESTINO y no con el animado: si siguiera la
    // animación, la máscara de la barra se recalcularía en cada fotograma para
    // nada.
    readonly property rect targetRect: {
        if (!root.shown || !root.occupant)
            return Qt.rect(0, 0, 0, 0)

        const w = root.occupant.currentWidth + root.hitPadding * 2
        const h = Math.max(root.occupant.currentHeight + root.hitPadding, 48)

        return Qt.rect(Math.round((root.width - w) / 2), 0, w, h)
    }

    onTargetRectChanged: IslandState.bodyRect = root.targetRect

    // ── la zona ───────────────────────────────────────────────────
    //
    // Es el PADRE de la silueta, y eso no es capricho de orden. Un detector de
    // hover ANCESTRO recibe el ratón aunque el contenido ponga cosas por
    // encima; uno hermano, no. Cuando el detector estaba dentro del contenido,
    // al desplegarse cambiaba la vista, el MouseArea perdía el ratón y la
    // tarjeta se cerraba sola — y al ir hacia un botón, igual.
    Item {
        id: hitArea

        x: Math.round((root.width - width) / 2)
        y: 0

        width: shape.width + root.hitPadding * 2
        height: shape.height + root.hitPadding

        HoverHandler {
            id: zoneHover

            onHoveredChanged: IslandState.hovered = zoneHover.hovered
        }

        IslandShape {
            id: shape

            x: root.hitPadding

            // Escondida, se va por arriba fuera de la pantalla. Este es el
            // estado POR DEFECTO de esta island: no hay píldora de reposo, así
            // que nadie la ocupa la mayor parte del tiempo.
            y: root.shown ? 0 : -(height + 8)

            // El item mide el notch entero, alas incluidas.
            width: root.occupant ? root.occupant.currentWidth : Theme.island.minWidth
            height: root.occupant ? root.occupant.currentHeight : Theme.island.closedHeight

            fill: Theme.island.bg

            topRadius: root.expanded ? Theme.island.openTopRadius
                                     : Theme.island.closedTopRadius
            bottomRadius: root.expanded ? Theme.island.openBottomRadius
                                        : Theme.island.closedBottomRadius

            opacity: root.shown ? 1 : 0

            Behavior on y {
                NumberAnimation {
                    duration: root.shown ? Theme.island.enterDuration
                                         : Theme.island.exitDuration
                    easing.type: root.shown ? Easing.OutBack : Easing.InQuad
                    easing.overshoot: Theme.island.openOvershoot
                }
            }

            Behavior on opacity {
                NumberAnimation {
                    duration: Theme.island.exitDuration
                }
            }

            // ── el estirón ────────────────────────────────────────
            //
            // Abrir y cerrar NO usan la misma curva, y eso es lo que más se
            // nota. Boring Notch abre con un muelle de amortiguación 0.8
            // —rebasa un pelo y vuelve— y cierra con 1.0, que es justo el
            // límite sin rebote.
            Behavior on width {
                NumberAnimation {
                    duration: root.expanded ? Theme.island.openDuration
                                            : Theme.island.closeDuration
                    easing.type: root.expanded ? Easing.OutBack : Easing.OutCubic
                    easing.overshoot: Theme.island.openOvershoot
                }
            }

            Behavior on height {
                NumberAnimation {
                    duration: root.expanded ? Theme.island.openDuration
                                            : Theme.island.closeDuration
                    easing.type: root.expanded ? Easing.OutBack : Easing.OutCubic
                    easing.overshoot: Theme.island.openOvershoot
                }
            }

            Behavior on topRadius {
                NumberAnimation {
                    duration: root.expanded ? Theme.island.openDuration
                                            : Theme.island.closeDuration
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on bottomRadius {
                NumberAnimation {
                    duration: root.expanded ? Theme.island.openDuration
                                            : Theme.island.closeDuration
                    easing.type: Easing.OutCubic
                }
            }

            // El hueco sin las alas. Recortado, para que una vista que todavía
            // no ha terminado de encogerse no se salga por los lados.
            Item {
                id: viewport

                x: shape.contentX
                y: 0
                width: shape.contentWidth
                height: shape.height
                clip: true

                // Solo para el clic y el cursor. SIN `hoverEnabled`: de eso se
                // encarga el detector de la zona, y dos detectores compitiendo
                // por el mismo ratón es justo lo que estaba fallando. Va antes
                // que el Loader para quedar debajo, así que los botones del
                // contenido se llevan sus clics primero.
                MouseArea {
                    anchors.fill: parent

                    cursorShape: root.occupant && root.occupant.expandable
                        ? Qt.PointingHandCursor
                        : Qt.ArrowCursor

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
}