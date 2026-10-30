// La llamada en curso, como en el iPhone: después de Contestar la isla no se
// va. Plegada es una píldora con el teléfono verde y el tiempo; desplegada, el
// contacto, el tiempo y los botones (audio, silenciar, más y colgar).
//
// Solo existe con ./install.sh --calls: es cuando la llamada pasa por la PC y
// BlueFerry la cuenta (Calls). Al contestar se abre unos segundos y se
// pliega; pasa el ratón para volver a abrirla.
//
// Prioridad 75: por debajo de las notificaciones (una notificación se ve un
// momento y la llamada vuelve) y por encima del volumen y la música. La que
// suena es otra cosa: la tarjeta de la notificación, con prioridad 120.

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.domain.phone

IslandOccupant {
    id: root

    name: "call"
    priority: 75

    active: Calls.ongoing

    contentWidth: 210
    contentHeight: Theme.island.closedHeight

    expandable: true
    expandOnHover: true
    expandedWidth: Theme.island.openWidth
    expandedHeight: 168

    readonly property color green: "#30d158"

    // El reloj. Solo corre mientras hay llamada.
    property real now: Date.now()

    Timer {
        interval: 1000
        repeat: true
        running: root.active
        triggeredOnStart: true
        onTriggered: root.now = Date.now()
    }

    readonly property string clock: Calls.clockAt(root.now)

    // Al contestar (o al empezar a marcar) se abre un momento, como el iPhone
    // justo después de contestar, y se pliega solo.
    Connections {
        target: Calls

        function onCurrentIdChanged() {
            if (!Calls.ongoing)
                return;
            root.expanded = true;
            fold.restart();
        }
    }

    Timer {
        id: fold
        interval: 5000
        onTriggered: {
            if (!root.pointerInside)
                root.expanded = false;
        }
    }

    // ── plegada: teléfono verde y tiempo; a la derecha, la voz ──────
    view: Component {
        Item {
            anchors.fill: parent

            Icon {
                id: phone

                anchors.left: parent.left
                anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter

                icon: Theme.systemIcons.call.phone
                size: 14
                color: root.green
            }

            Label {
                anchors.left: phone.right
                anchors.leftMargin: 7
                anchors.verticalCenter: parent.verticalCenter

                text: root.clock
                color: root.green
                font.pixelSize: 13
                font.weight: Font.DemiBold
                font.features: { "tnum": 1 }
            }

            // Silenciado: el micrófono tachado. Si no, unos puntos que laten,
            // como la onda del iPhone.
            Icon {
                visible: Calls.muted
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter

                icon: Theme.systemIcons.call.micOff
                size: 13
                color: "#ff9f0a"
            }

            Row {
                visible: !Calls.muted
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 3

                Repeater {
                    model: 7

                    Rectangle {
                        id: dot

                        required property int index

                        // Sin valor inicial: la animación es su única fuente.
                        property real level

                        width: 3
                        height: 3
                        radius: 1.5
                        color: "#ffd60a"
                        opacity: 0.35 + dot.level * 0.65

                        SequentialAnimation on level {
                            running: Calls.ongoing && !Calls.muted
                            loops: Animation.Infinite

                            PauseAnimation { duration: dot.index * 90 }
                            NumberAnimation { to: 1; duration: 320; easing.type: Easing.InOutSine }
                            NumberAnimation { to: 0; duration: 320; easing.type: Easing.InOutSine }
                            PauseAnimation { duration: (6 - dot.index) * 90 }
                        }
                    }
                }
            }
        }
    }

    // ── desplegada: contacto y tiempo; abajo, los botones ──────────
    expandedView: Component {
        Item {
            anchors.fill: parent
            anchors.topMargin: Theme.island.openTopRadius
            anchors.leftMargin: 26
            anchors.rightMargin: 26
            anchors.bottomMargin: 20

            // La inicial en un círculo, como el iPhone sin foto del contacto.
            // Si solo hay número, la silueta de una persona.
            Avatar {
                id: avatar

                anchors.left: parent.left
                anchors.top: parent.top

                size: 54
                name: Calls.looksLikeNumber(Calls.name) ? "" : Calls.name
                fallbackIcon: Theme.systemIcons.user
            }

            Column {
                anchors.left: avatar.right
                anchors.leftMargin: 14
                anchors.right: parent.right
                anchors.verticalCenter: avatar.verticalCenter
                spacing: 2

                Label {
                    width: parent.width
                    text: Calls.name
                    color: Theme.island.fg
                    font.pixelSize: 17
                    font.weight: Font.DemiBold
                    elide: Text.ElideRight
                }

                Label {
                    width: parent.width
                    text: root.clock
                    color: Theme.island.muted
                    font.pixelSize: 13
                    font.features: { "tnum": 1 }
                }
            }

            Row {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                spacing: (width - 4 * root.button) / 3

                // Audio: pasa a la siguiente salida (bocinas, audífonos…).
                IslandButton {
                    width: root.button
                    height: root.button
                    icon: Theme.systemIcons.call.speaker
                    hint: Calls.output ? Calls.output.label : "Audio"
                    onTapped: Calls.nextOutput()
                }

                // Silenciar: blanco mientras está silenciado, como en el iPhone.
                IslandButton {
                    width: root.button
                    height: root.button
                    icon: Calls.muted ? Theme.systemIcons.call.micOff : Theme.systemIcons.call.mic
                    hint: Calls.muted ? "Activar micrófono" : "Silenciar"
                    on: Calls.muted
                    onTapped: Calls.toggleMute()
                }

                // Más: la ventana de llamadas de BlueFerry (teclado, retener…).
                IslandButton {
                    width: root.button
                    height: root.button
                    icon: Theme.systemIcons.call.more
                    hint: "Más en BlueFerry"
                    onTapped: PhoneService.openApp()
                }

                IslandButton {
                    width: root.button
                    height: root.button
                    icon: Theme.systemIcons.call.phone
                    iconRotation: 135
                    hint: "Colgar"
                    tint: "#ff453a"
                    onTapped: Calls.hangUp()
                }
            }
        }
    }

    // Los botones redondos de abajo.
    readonly property int button: 48
}
