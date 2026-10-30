// Lo que suena. A diferencia del volumen, este NO se va solo: mientras haya
// pista se queda plegado en forma de notch, y se despliega al pasarle el ratón.
//
// Y justo por eso es el único que se calla en pantalla completa. Un ocupante
// permanente encima de un vídeo o un juego es una mancha fija; una notificación
// de cuatro segundos no. La decisión vive en `active`, que es la propiedad que
// contesta a "¿tengo algo que enseñar ahora mismo?".
//
// Plegado tiene las medidas de Boring Notch (185x32, carátula de 20 px).
// Desplegado (640x190) se ve como el reproductor de macOS: la carátula grande
// con su halo, el programa que suena en la esquina y la línea de tiempo que
// se arrastra.
//
// Las dos carátulas son CoverArt: sin imagen, la nota o la tele según
// Player.kind.

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.domain.media
import qs.domain.island

IslandOccupant {
    id: root

    name: "player"
    priority: 40

    // La regla vive en el dominio de la isla (IslandOccupants.fullscreen) y
    // lee el mismo dato de Hyprland que usa la barra: una sola fuente.
    readonly property bool allowed: !IslandOccupants.fullscreen

    active: Player.hasTrack && root.allowed

    contentWidth: Theme.island.minWidth
    contentHeight: Theme.island.closedHeight

    expandable: true
    expandOnHover: true
    expandedWidth: Theme.island.openWidth
    expandedHeight: Theme.island.openHeight

    // ── cerrado: carátula a la izquierda, visualizador a la derecha ──
    view: Component {
        Item {
            anchors.fill: parent

            // Chica, sin halo: en 32 px de alto se saldría de la isla.
            CoverArt {
                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter

                width: Theme.island.artClosed
                height: Theme.island.artClosed
                radius: Theme.island.artClosedRadius

                source: Player.artUrl
                glyph: Theme.systemIcons.cover[Player.kind]
                glyphSize: 11
            }

            // Cuatro barras que suben y bajan desfasadas. Cada una va dentro de
            // su propio Item: dentro de un Row no se pueden usar anclas contra
            // el positionador, pero sí contra un padre propio.
            Row {
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Repeater {
                    model: 4

                    Item {
                        id: slot

                        required property int index

                        width: 3
                        height: 16

                        Rectangle {
                            id: bar

                            // Sin valor inicial: la animación es su única fuente (empieza en 0).
                            property real level

                            anchors.centerIn: parent
                            width: parent.width
                            radius: width / 2
                            color: Theme.island.fg

                            // Quieto, cuatro puntos. Sonando, un visualizador.
                            height: Player.isPlaying ? 4 + bar.level * 10 : 4

                            SequentialAnimation on level {
                                running: Player.isPlaying
                                loops: Animation.Infinite

                                PauseAnimation {
                                    duration: slot.index * 110
                                }

                                NumberAnimation {
                                    to: 1
                                    duration: 330
                                    easing.type: Easing.InOutSine
                                }

                                NumberAnimation {
                                    to: 0
                                    duration: 330
                                    easing.type: Easing.InOutSine
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // ── abierto: como el reproductor de macOS ──────────────────────
    //
    // La carátula grande a la izquierda. A la derecha: arriba el título y
    // "artista — disco", y en la esquina el programa que suena; al centro los
    // botones, con reproducir/pausar en un círculo; abajo la línea de tiempo,
    // que se arrastra para adelantar o regresar.
    expandedView: Component {
        Item {
            anchors.fill: parent
            // La carátula cerca del borde, como en macOS, pero con aire para
            // que su halo asome también por la izquierda. El cuerpo de la isla
            // empieza después de las alas (openTopRadius).
            anchors.topMargin: Theme.island.openTopRadius
            anchors.leftMargin: Theme.island.openStart
            anchors.rightMargin: Theme.island.openEnd
            anchors.bottomMargin: Theme.island.openBottom

            // `position` no se actualiza sola. Mientras esta vista exista,
            // alguien tiene que pedirle al reproductor que lo diga.
            Component.onCompleted: Player.watchPosition()
            Component.onDestruction: Player.unwatchPosition()

            // Con su halo: la carátula difuminada asoma por los bordes.
            CoverArt {
                id: bigCover

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                width: Theme.island.artOpen
                height: Theme.island.artOpen
                radius: Theme.island.artOpenRadius
                decodeSize: Theme.island.artOpen * 2

                source: Player.artUrl
                glyph: Theme.systemIcons.cover[Player.kind]
                glyphSize: 48
                glow: true
            }

            // Todo lo de la derecha vive dentro de la altura de la carátula.
            Item {
                id: side

                anchors.left: bigCover.right
                anchors.leftMargin: Theme.island.openGap
                anchors.right: parent.right
                anchors.top: bigCover.top
                anchors.bottom: bigCover.bottom
            }

            // El programa que suena, en la esquina, con sus tres barras.
            Row {
                id: source

                anchors.right: side.right
                anchors.top: side.top
                anchors.topMargin: 2

                visible: Player.source.length > 0
                spacing: 6

                Row {
                    anchors.bottom: sourceName.baseline
                    spacing: 1.5

                    Repeater {
                        model: [4, 7, 10]

                        Rectangle {
                            required property int modelData

                            anchors.bottom: parent.bottom
                            width: 2.5
                            height: modelData
                            radius: 1
                            color: Theme.island.muted
                        }
                    }
                }

                Label {
                    id: sourceName

                    text: Player.source
                    color: Theme.island.muted
                    font.pixelSize: Theme.island.openCaption
                }
            }

            Column {
                id: header

                anchors.left: side.left
                anchors.right: source.visible ? source.left : side.right
                anchors.rightMargin: source.visible ? 14 : 0
                anchors.top: side.top

                spacing: 3

                Label {
                    width: parent.width
                    text: Player.title
                    color: Theme.island.fg
                    font.pixelSize: Theme.island.openTitle
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Label {
                    width: parent.width
                    visible: Player.subtitle.length > 0
                    text: Player.subtitle
                    color: Theme.island.muted
                    font.pixelSize: Theme.island.openSubtitle
                    elide: Text.ElideRight
                }
            }

            // Anterior · reproducir/pausar · siguiente. Los de los lados sin
            // fondo; el del centro en su círculo, como en macOS.
            Row {
                id: controls

                anchors.horizontalCenter: side.horizontalCenter
                anchors.bottom: timeline.visible ? timeline.top : side.bottom
                anchors.bottomMargin: timeline.visible ? 10 : 0

                spacing: 18

                IslandButton {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    height: 40
                    flat: true
                    enabled: Player.canGoPrevious
                    icon: Theme.systemIcons.transport.previous
                    iconFamily: Theme.font.mono
                    iconSize: 17
                    onTapped: Player.previous()
                }

                IslandButton {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 44
                    height: 44
                    enabled: Player.canControl
                    icon: Player.isPlaying ? Theme.systemIcons.transport.pause
                                           : Theme.systemIcons.transport.play
                    iconFamily: Theme.font.mono
                    iconSize: 17
                    onTapped: Player.togglePlaying()
                }

                IslandButton {
                    anchors.verticalCenter: parent.verticalCenter
                    width: 40
                    height: 40
                    flat: true
                    enabled: Player.canGoNext
                    icon: Theme.systemIcons.transport.next
                    iconFamily: Theme.font.mono
                    iconSize: 17
                    onTapped: Player.next()
                }
            }

            // 0:05 ──●────────── 4:58
            Item {
                id: timeline

                anchors.left: side.left
                anchors.right: side.right
                anchors.bottom: side.bottom

                height: 14
                visible: Player.hasTimeline

                Label {
                    id: elapsed

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    width: 34
                    text: Player.elapsed
                    color: Theme.island.muted
                    font.pixelSize: Theme.island.openCaption
                    font.features: { "tnum": 1 }
                }

                Label {
                    id: duration

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    width: 34
                    text: Player.duration
                    color: Theme.island.muted
                    font.pixelSize: Theme.island.openCaption
                    font.features: { "tnum": 1 }
                    horizontalAlignment: Text.AlignRight
                }

                ScrubBar {
                    anchors.left: elapsed.right
                    anchors.leftMargin: 8
                    anchors.right: duration.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter

                    value: Player.progress
                    seekable: Player.canSeek
                    onSeeked: value => Player.seekTo(value)
                }
            }
        }
    }

    // Si la música se acaba mientras está desplegado, que no se quede el hueco
    // abierto esperando a nadie.
    Connections {
        target: Player

        function onHasTrackChanged() {
            if (!Player.hasTrack)
                root.collapse();
        }
    }

    // Lo mismo al entrar en pantalla completa: se repliega además de retirarse.
    // Sin esto, `expanded` se queda en true mientras nadie lo ve, y al salir de
    // pantalla completa la isla volvería abierta de golpe en 640x190.
    onAllowedChanged: {
        if (!root.allowed)
            root.collapse();
    }
}