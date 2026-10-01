// Lo que acaba de llegar. Prioridad por encima del volumen y del reproductor:
// una notificación interrumpe, es su trabajo.
//
// No usa `ephemeral` del contrato, y esa es la diferencia con los otros dos.
// El volumen y el reproductor son ESTADOS: siempre hay un valor que leer. Una
// notificación es un EVENTO, y los eventos llegan en ráfaga y hacen cola. Quien
// decide cuándo se va no es un temporizador de retirada, es la cola.

import QtQuick
import Quickshell
import Quickshell.Widgets
import qs.core.theme
import qs.core.components.atoms
import qs.domain.notifications

IslandOccupant {
    id: root

    name: "notification"
    priority: 80

    active: Notifications.hasCurrent

    contentWidth: 320
    contentHeight: Theme.island.closedHeight

    expandable: true
    expandOnHover: true
    expandedWidth: Theme.island.openWidth
    expandedHeight: Theme.island.openHeight

    // Cuánto dura cada una en pantalla.
    property int showFor: 4200

    // El reloj de la cola.
    //
    // `repeat: true` y no `false`: un Timer sin repetición se apaga solo al
    // disparar, y apagarse solo ROMPE el binding de `running` — a partir de
    // ahí no vuelve a arrancar nunca.
    Timer {
        interval: root.showFor
        repeat: true
        running: root.active && !root.pointerInside && !root.isExpanded
        onTriggered: Notifications.advance()
    }

    // ── cerrado: icono y resumen ──────────────────────────────────
    view: Component {
        Item {
            anchors.fill: parent

            // La acción "default" de la especificación: lo que pasa al pulsar
            // el cuerpo. En WhatsApp es abrir la conversación.
            TapHandler {
                enabled: Notifications.hasDefaultAction
                onTapped: Notifications.invokeDefault()
            }

            IconImage {
                id: icon

                anchors.left: parent.left
                anchors.leftMargin: 7
                anchors.verticalCenter: parent.verticalCenter

                implicitSize: Theme.island.artClosed

                source: Notifications.image.length > 0
                    ? Notifications.image
                    : Quickshell.iconPath(Notifications.appIcon, "dialog-information")
            }

            Label {
                anchors.left: icon.right
                anchors.leftMargin: 9
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter

                text: Notifications.summary
                color: Theme.island.fg
                font.pixelSize: 12
                elide: Text.ElideRight
            }
        }
    }

    // ── abierto: 640x190 ──────────────────────────────────────────
    expandedView: Component {
        Item {
            anchors.fill: parent
            anchors.topMargin: Theme.island.openTopRadius
            anchors.leftMargin: 26
            anchors.rightMargin: 26
            anchors.bottomMargin: 22

            IconImage {
                id: bigIcon

                anchors.left: parent.left
                anchors.top: parent.top

                implicitSize: 56

                source: Notifications.image.length > 0
                    ? Notifications.image
                    : Quickshell.iconPath(Notifications.appIcon, "dialog-information")
            }

            Column {
                anchors.left: bigIcon.right
                anchors.leftMargin: Theme.island.spacing
                anchors.right: parent.right
                anchors.top: parent.top

                spacing: 4

                Label {
                    width: parent.width
                    text: Notifications.appName
                    color: Theme.island.muted
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                Label {
                    width: parent.width
                    text: Notifications.summary
                    color: Theme.island.fg
                    font.pixelSize: 16
                    font.bold: true
                    elide: Text.ElideRight
                }

                Label {
                    width: parent.width
                    text: Notifications.body
                    color: Theme.island.muted
                    font.pixelSize: 13

                    // Texto plano a propósito: el servidor no anuncia marcado,
                    // así que lo que llega es texto y así se pinta.
                    textFormat: Text.PlainText
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
            }

            // Ni un solo `MouseArea` con `hoverEnabled` aquí dentro: uno que
            // acepta hover se lo quita al detector que está debajo, y la
            // tarjeta se cerraría justo al ir a pulsar el botón.
            Row {
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                spacing: 10

                Repeater {
                    model: Notifications.actions

                    Rectangle {
                        id: actionButton

                        required property var modelData

                        width: actionLabel.implicitWidth + 28
                        height: 32
                        radius: 16
                        color: actionHover.hovered
                            ? Qt.rgba(1, 1, 1, 0.3)
                            : Theme.island.track

                        Behavior on color {
                            ColorAnimation {
                                duration: Theme.motion.duration
                            }
                        }

                        Label {
                            id: actionLabel

                            anchors.centerIn: parent
                            text: actionButton.modelData.text
                            color: Theme.island.fg
                            font.pixelSize: 12
                        }

                        HoverHandler {
                            id: actionHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: Notifications.invoke(actionButton.modelData)
                        }
                    }
                }

                Rectangle {
                    width: dismissLabel.implicitWidth + 28
                    height: 32
                    radius: 16
                    color: dismissHover.hovered
                        ? Qt.rgba(1, 1, 1, 0.3)
                        : Theme.island.track

                    Behavior on color {
                        ColorAnimation {
                            duration: Theme.motion.duration
                        }
                    }

                    Label {
                        id: dismissLabel

                        anchors.centerIn: parent
                        text: "Descartar"
                        color: Theme.island.fg
                        font.pixelSize: 12
                    }

                    HoverHandler {
                        id: dismissHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: Notifications.dismissCurrent()
                    }
                }
            }
        }
    }
}