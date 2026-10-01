// Lo que suena. A diferencia del volumen, este NO se va solo: mientras haya
// pista se queda plegado en forma de notch, y se despliega al pasarle el ratón.
//
// Las medidas son las de Boring Notch: 185x32 cerrado, 640x190 abierto, y la
// carátula de 20px con radio 4 a 90px con radio 13.

import QtQuick
import Quickshell.Widgets
import qs.core.theme
import qs.core.components.atoms
import qs.domain.media

IslandOccupant {
    id: root

    name: "player"
    priority: 40

    active: Player.hasTrack

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

            ClippingRectangle {
                id: cover

                anchors.left: parent.left
                anchors.leftMargin: 6
                anchors.verticalCenter: parent.verticalCenter

                width: Theme.island.artClosed
                height: Theme.island.artClosed
                radius: Theme.island.artClosedRadius
                color: Theme.island.track

                Image {
                    anchors.fill: parent
                    source: Player.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    sourceSize.width: 64
                    sourceSize.height: 64
                }
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

                            property real level: 0

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

    // ── abierto: 640x190, la vista principal de Boring Notch ────────
    expandedView: Component {
        Item {
            anchors.fill: parent
            anchors.topMargin: Theme.island.openTopRadius
            anchors.leftMargin: 26
            anchors.rightMargin: 26
            anchors.bottomMargin: 22

            // `position` no se actualiza sola. Mientras esta vista exista,
            // alguien tiene que pedirle al reproductor que lo diga.
            Component.onCompleted: Player.watchPosition()
            Component.onDestruction: Player.unwatchPosition()

            ClippingRectangle {
                id: bigCover

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                width: Theme.island.artOpen
                height: Theme.island.artOpen
                radius: Theme.island.artOpenRadius
                color: Theme.island.track

                Image {
                    anchors.fill: parent
                    source: Player.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true
                    sourceSize.width: 180
                    sourceSize.height: 180
                }
            }

            Column {
                id: header

                anchors.left: bigCover.right
                anchors.leftMargin: Theme.island.spacing
                anchors.right: parent.right
                anchors.top: parent.top

                spacing: 2

                Label {
                    width: parent.width
                    text: Player.title
                    color: Theme.island.fg
                    font.pixelSize: 17
                    font.bold: true
                    elide: Text.ElideRight
                }

                Label {
                    width: parent.width
                    text: Player.artist
                    color: Theme.island.muted
                    font.pixelSize: 13
                    elide: Text.ElideRight
                }
            }

            Item {
                id: timeline

                anchors.left: bigCover.right
                anchors.leftMargin: Theme.island.spacing
                anchors.right: parent.right
                anchors.top: header.bottom
                anchors.topMargin: 16

                height: 16
                visible: Player.hasTimeline

                Label {
                    id: elapsed

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    width: 38
                    text: Player.elapsed
                    color: Theme.island.muted
                    font.pixelSize: 11
                }

                Label {
                    id: remaining

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    width: 38
                    text: Player.remaining
                    color: Theme.island.muted
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignRight
                }

                Rectangle {
                    anchors.left: elapsed.right
                    anchors.leftMargin: 10
                    anchors.right: remaining.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter

                    height: 5
                    radius: height / 2
                    color: Theme.island.track

                    Rectangle {
                        width: parent.width * Player.progress
                        height: parent.height
                        radius: parent.radius
                        color: Theme.island.fg

                        // El reloj late una vez por segundo; la animación
                        // rellena el hueco para que no avance a saltos.
                        Behavior on width {
                            NumberAnimation {
                                duration: 1000
                                easing.type: Easing.Linear
                            }
                        }
                    }
                }
            }

            Row {
                anchors.horizontalCenter: timeline.horizontalCenter
                anchors.bottom: parent.bottom

                spacing: 38

                Item {
                    width: 46
                    height: 36

                    opacity: Player.canGoPrevious ? 1 : 0.35

                    Label {
                        anchors.centerIn: parent
                        text: Player.previousIcon
                        color: Theme.island.fg
                        font.family: Theme.font.mono
                        font.pixelSize: 20
                    }

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        enabled: Player.canGoPrevious
                        onTapped: Player.previous()
                    }
                }

                Item {
                    width: 46
                    height: 36

                    opacity: Player.canControl ? 1 : 0.35

                    Label {
                        anchors.centerIn: parent
                        text: Player.playIcon
                        color: Theme.island.fg
                        font.family: Theme.font.mono
                        font.pixelSize: 26
                    }

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        enabled: Player.canControl
                        onTapped: Player.togglePlaying()
                    }
                }

                Item {
                    width: 46
                    height: 36

                    opacity: Player.canGoNext ? 1 : 0.35

                    Label {
                        anchors.centerIn: parent
                        text: Player.nextIcon
                        color: Theme.island.fg
                        font.family: Theme.font.mono
                        font.pixelSize: 20
                    }

                    HoverHandler {
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        enabled: Player.canGoNext
                        onTapped: Player.next()
                    }
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
}