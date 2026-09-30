// Lo que suena. A diferencia del volumen, este NO se va solo: mientras haya
// pista se queda plegado en forma de píldora, y se despliega al pasarle el
// ratón por encima.
//
// Prioridad por debajo del volumen a propósito: subir el volumen interrumpe la
// carátula un par de segundos y después la píldora vuelve sola. Salvo que esté
// desplegado, que entonces manda él.

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

    // Mismo alto que el volumen: la island cambia de ancho al cambiar de
    // inquilino, nunca de alto.
    contentWidth: 190
    contentHeight: Theme.island.pillHeight

    expandable: true
    expandOnHover: true
    expandedWidth: 420
    expandedHeight: 200

    // ── plegado: carátula a la izquierda, visualizador a la derecha ──
    view: Component {
        Item {
            anchors.fill: parent

            ClippingRectangle {
                id: cover

                anchors.left: parent.left
                anchors.leftMargin: 7
                anchors.verticalCenter: parent.verticalCenter

                width: parent.height - 14
                height: width
                radius: 9
                color: Theme.island.track

                Image {
                    anchors.fill: parent
                    source: Player.artUrl
                    fillMode: Image.PreserveAspectCrop
                    asynchronous: true
                    cache: true

                    // Decodificar la carátula a su tamaño real y no a los
                    // 1000×1000 que manda el reproductor. Sin esto, cada
                    // cambio de pista descomprime una imagen enorme para
                    // pintarla en 30 píxeles, justo cuando hay animación.
                    sourceSize.width: 64
                    sourceSize.height: 64
                }
            }

            // Cuatro barras que suben y bajan desfasadas. Cada una va dentro de
            // su propio Item: dentro de un Row no se pueden usar anclas contra
            // el positionador, pero sí contra un padre propio.
            Row {
                anchors.right: parent.right
                anchors.rightMargin: Theme.island.pillPadding
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Repeater {
                    model: 4

                    Item {
                        id: slot

                        required property int index

                        width: 3
                        height: 18

                        Rectangle {
                            id: bar

                            property real level: 0

                            anchors.centerIn: parent
                            width: parent.width
                            radius: width / 2
                            color: Theme.island.fg

                            // Quieto, cuatro puntos. Sonando, un visualizador.
                            height: Player.isPlaying ? 4 + bar.level * 12 : 4

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

    // ── desplegado: carátula grande, tiempos y transporte ───────────
    expandedView: Component {
        Item {
            anchors.fill: parent

            // `position` no se actualiza sola. Mientras esta vista exista,
            // alguien tiene que pedirle al reproductor que lo diga.
            Component.onCompleted: Player.watchPosition()
            Component.onDestruction: Player.unwatchPosition()

            Item {
                id: header

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 18

                height: 64

                ClippingRectangle {
                    id: bigCover

                    width: 64
                    height: 64
                    radius: 14
                    color: Theme.island.track

                    Image {
                        anchors.fill: parent
                        source: Player.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        sourceSize.width: 128
                        sourceSize.height: 128
                    }
                }

                Column {
                    anchors.left: bigCover.right
                    anchors.leftMargin: 14
                    anchors.right: parent.right
                    anchors.verticalCenter: bigCover.verticalCenter

                    spacing: 3

                    Label {
                        width: parent.width
                        text: Player.headline
                        color: Theme.island.fg
                        font.pixelSize: 15
                        font.bold: true
                        elide: Text.ElideRight
                    }

                    Label {
                        width: parent.width
                        text: Player.playingOn
                        color: Theme.island.muted
                        font.pixelSize: 13
                        elide: Text.ElideRight
                    }
                }
            }

            Item {
                id: timeline

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                anchors.top: header.bottom
                anchors.topMargin: 18

                height: 14
                visible: Player.hasTimeline

                Label {
                    id: elapsed

                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter

                    width: 34
                    text: Player.elapsed
                    color: Theme.island.muted
                    font.pixelSize: 11
                }

                Label {
                    id: remaining

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter

                    width: 34
                    text: Player.remaining
                    color: Theme.island.muted
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignRight
                }

                Rectangle {
                    anchors.left: elapsed.right
                    anchors.leftMargin: 8
                    anchors.right: remaining.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter

                    height: 5
                    radius: height / 2
                    color: Theme.island.track

                    Rectangle {
                        width: parent.width * Player.progress
                        height: parent.height
                        radius: parent.radius
                        color: Theme.island.muted

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
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 20

                spacing: 32

                Item {
                    width: 44
                    height: 34

                    opacity: Player.canGoPrevious ? 1 : 0.35

                    Label {
                        anchors.centerIn: parent
                        text: Player.previousIcon
                        color: Theme.island.fg
                        font.family: Theme.font.mono
                        font.pixelSize: 20
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: Player.canGoPrevious
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Player.previous()
                    }
                }

                Item {
                    width: 44
                    height: 34

                    opacity: Player.canControl ? 1 : 0.35

                    Label {
                        anchors.centerIn: parent
                        text: Player.playIcon
                        color: Theme.island.fg
                        font.family: Theme.font.mono
                        font.pixelSize: 26
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: Player.canControl
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Player.togglePlaying()
                    }
                }

                Item {
                    width: 44
                    height: 34

                    opacity: Player.canGoNext ? 1 : 0.35

                    Label {
                        anchors.centerIn: parent
                        text: Player.nextIcon
                        color: Theme.island.fg
                        font.family: Theme.font.mono
                        font.pixelSize: 20
                    }

                    MouseArea {
                        anchors.fill: parent
                        enabled: Player.canGoNext
                        cursorShape: Qt.PointingHandCursor
                        onClicked: Player.next()
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