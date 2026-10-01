// Lo que acaba de llegar. Prioridad por encima del volumen y del reproductor:
// una notificación interrumpe, es su trabajo.
//
// No usa `ephemeral` del contrato, y esa es la diferencia con los otros dos.
// El volumen y el reproductor son ESTADOS: siempre hay un valor que leer. Una
// notificación es un EVENTO, y los eventos llegan en ráfaga y hacen cola. Quien
// decide cuándo se va no es un temporizador de retirada, es la cola.
//
// Todo lo que pinta sale ya tipado del dominio. Aquí no hay un solo `split`,
// ni un emoji, ni un "si viene de BlueFerry entonces": eso vive en
// NotificationTypes, que es el único archivo que hay que tocar cuando un
// puente cambia de formato.

import QtQuick
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
    // disparar, y apagarse solo ROMPE el binding de `running` — a partir de ahí
    // no vuelve a arrancar nunca. Con repetición, cada vuelta pasa a la
    // siguiente y el binding sigue vivo.
    //
    // Y al pararse se reinicia, así que quitar el ratón le da el tiempo
    // completo otra vez en lugar de lo que quedara.
    Timer {
        interval: root.showFor
        repeat: true
        running: root.active && !root.pointerInside && !root.isExpanded
        onTriggered: Notifications.advance()
    }

    // ── plegado: símbolo, quién y qué ─────────────────────────────
    view: Component {
        Item {
            anchors.fill: parent

            // Toda la píldora es la acción por defecto, cuando la hay. Sin
            // `hoverEnabled` en ningún sitio: un TapHandler no roba el hover,
            // y el de la superficie tiene que seguir llegando.
            TapHandler {
                enabled: Notifications.hasDefaultAction
                onTapped: Notifications.invokeDefault()
            }

            AppBadge {
                id: badge

                anchors.left: parent.left
                anchors.leftMargin: 7
                anchors.verticalCenter: parent.verticalCenter

                size: Theme.island.artClosed

                image: Notifications.image
                icon: Notifications.icon
                glyph: Notifications.glyph
                fontFamily: Theme.font.mono
                color: Theme.island.fg
            }

            // Quien manda el mensaje; si no hay remitente, la aplicación.
            Label {
                id: who

                anchors.left: badge.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter

                // Se queda con lo que necesite, pero nunca más de la mitad:
                // un nombre largo no puede comerse el mensaje entero.
                width: Math.min(who.implicitWidth, parent.width * 0.45)

                text: Notifications.title.length > 0
                    ? Notifications.title
                    : Notifications.appName

                color: Theme.island.fg
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
            }

            Label {
                anchors.left: who.right
                anchors.leftMargin: 7
                anchors.right: parent.right
                anchors.rightMargin: 10
                anchors.verticalCenter: parent.verticalCenter

                text: Notifications.message
                color: Theme.island.muted
                font.pixelSize: 12

                // Texto plano: el servidor anuncia `bodyMarkupSupported: false`,
                // así que lo que llega es texto y así se pinta. Lo que venía
                // escapado ya lo desescapó el dominio.
                textFormat: Text.PlainText
                elide: Text.ElideRight
            }
        }
    }

    // ── desplegado: la tarjeta ────────────────────────────────────
    expandedView: Component {
        Item {
            anchors.fill: parent
            anchors.topMargin: Theme.island.openTopRadius
            anchors.leftMargin: 26
            anchors.rightMargin: 26
            anchors.bottomMargin: 22

            AppBadge {
                id: bigBadge

                anchors.left: parent.left
                anchors.top: parent.top

                size: 56

                image: Notifications.image
                icon: Notifications.icon
                glyph: Notifications.glyph
                fontFamily: Theme.font.mono
                color: Theme.island.fg
            }

            Column {
                anchors.left: bigBadge.right
                anchors.leftMargin: Theme.island.spacing
                anchors.right: parent.right
                anchors.top: parent.top

                spacing: 4

                // La aplicación de verdad: "WhatsApp", no "BlueFerry".
                Label {
                    width: parent.width
                    text: Notifications.appName
                    color: Theme.island.muted
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                // El remitente. Se oculta cuando no hay: una notificación de
                // sistema no tiene a nadie detrás, y una línea vacía se nota.
                Label {
                    width: parent.width
                    visible: Notifications.title.length > 0

                    text: Notifications.title
                    color: Theme.island.fg
                    font.pixelSize: 16
                    font.bold: true
                    elide: Text.ElideRight
                }

                Label {
                    width: parent.width
                    text: Notifications.message
                    color: Theme.island.muted
                    font.pixelSize: 13

                    textFormat: Text.PlainText
                    wrapMode: Text.WordWrap
                    maximumLineCount: 3
                    elide: Text.ElideRight
                }
            }

            // Las acciones que manda la aplicación, y al final el descarte, que
            // es nuestro y siempre está.
            //
            // HoverHandler y TapHandler, nunca un MouseArea con `hoverEnabled`:
            // un MouseArea que acepta hover se lo queda, el detector de la
            // superficie deja de verlo y la tarjeta se cierra justo cuando vas
            // a pulsar el botón. Esto ya nos pasó.
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