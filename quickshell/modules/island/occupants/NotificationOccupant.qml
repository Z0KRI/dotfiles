// Lo que acaba de llegar. Prioridad por encima del volumen y del reproductor:
// una notificación interrumpe, es su trabajo. Y una llamada interrumpe a la
// notificación.
//
// Cuatro vistas, no dos. Una llamada entrante y un mensaje no se parecen en
// nada: la llamada se abre sola y espera una decisión, el mensaje espera una
// respuesta. Se eligen con `Notifications.kind`, que ya viene tipado — aquí no
// hay un solo `split` ni un emoji.
//
// Regla de toda vista de la isla: HoverHandler y TapHandler, nunca un MouseArea
// con `hoverEnabled`. Un MouseArea que acepta hover se lo queda, el detector de
// la superficie deja de verlo y la tarjeta se cierra justo al ir a pulsar.

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.domain.notifications
import qs.domain.phone

IslandOccupant {
    id: root

    name: "notification"

    // Una llamada no la desbanca nada.
    priority: root.isCall ? 120 : 80

    active: Notifications.hasCurrent

    readonly property bool isCall: Notifications.kind === "call"

    contentWidth: root.isCall ? 280 : 320
    contentHeight: Theme.island.closedHeight

    expandable: true

    // Una llamada no se abre al pasar el ratón: se abre sola y se queda. Con
    // esto apagado, los temporizadores de hover del contrato no tocan
    // `expanded`, así que sacar el ratón no cierra una llamada sonando.
    expandOnHover: !root.isCall

    expandedWidth: Theme.island.openWidth
    expandedHeight: Theme.island.openHeight

    view: root.isCall ? root.callClosed : root.toastClosed
    expandedView: root.isCall ? root.callOpen : root.toastOpen

    // Cuánto dura cada notificación en pantalla.
    property int showFor: 4200

    // El reloj de la cola.
    //
    // `repeat: true` y no `false`: un Timer sin repetición se apaga solo al
    // disparar, y apagarse ROMPE el binding de `running` — a partir de ahí no
    // vuelve a arrancar nunca. Con repetición, cada vuelta pasa a la siguiente
    // y el binding sigue vivo. Y al pararse se reinicia, así que quitar el
    // ratón da el tiempo completo otra vez.
    //
    // `!Notifications.holds`: una llamada no se va por tiempo. La cierra
    // BlueFerry cuando deja de sonar, y de eso se encarga `prune()`.
    Timer {
        interval: root.showFor
        repeat: true
        running: root.active
                 && !root.pointerInside
                 && !root.isExpanded
                 && !Notifications.holds
        onTriggered: Notifications.advance()
    }

    // Una llamada se despliega sola en cuanto entra.
    Connections {
        target: Notifications

        function onKindChanged() {
            if (Notifications.kind === "call")
                root.expanded = true;
            else
                root.collapse();
        }
    }

    // Busca una acción por su identificador. La llamada trae "answer" y
    // "decline"; `Notifications.actions` las lleva, pero en una vista de
    // llamada cada botón quiere la suya, no la lista.
    function action(id): var {
        const list = Notifications.allActions;

        for (let i = 0; i < list.length; ++i) {
            if (list[i] && list[i].identifier === id)
                return list[i];
        }

        return null;
    }

    // ── llamada, plegada ──────────────────────────────────────────
    property Component callClosed: Component {
        Item {
            anchors.fill: parent

            Label {
                id: ring

                anchors.left: parent.left
                anchors.leftMargin: 11
                anchors.verticalCenter: parent.verticalCenter

                text: "\uf095"
                color: "#30d158"
                font.family: Theme.font.mono
                font.pixelSize: 15

                // Latido mientras suena, para que se note de reojo.
                SequentialAnimation on opacity {
                    running: true
                    loops: Animation.Infinite

                    NumberAnimation { to: 0.35; duration: 600; easing.type: Easing.InOutSine }
                    NumberAnimation { to: 1;    duration: 600; easing.type: Easing.InOutSine }
                }
            }

            Label {
                anchors.left: ring.right
                anchors.leftMargin: 9
                anchors.right: parent.right
                anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter

                text: Notifications.title
                color: Theme.island.fg
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
            }
        }
    }

    // ── llamada, desplegada ───────────────────────────────────────
    property Component callOpen: Component {
        Item {
            anchors.fill: parent
            anchors.topMargin: Theme.island.openTopRadius
            anchors.leftMargin: 26
            anchors.rightMargin: 26
            anchors.bottomMargin: 22

            AppBadge {
                id: face

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                size: 72

                image: Notifications.image
                icon: ""
                glyph: "\uf095"
                fontFamily: Theme.font.mono
                color: Theme.island.fg
            }

            Column {
                anchors.left: face.right
                anchors.leftMargin: Theme.island.spacing
                anchors.right: buttons.left
                anchors.rightMargin: Theme.island.spacing
                anchors.verticalCenter: parent.verticalCenter

                spacing: 3

                Label {
                    width: parent.width
                    text: Notifications.appName
                    color: Theme.island.muted
                    font.pixelSize: 11
                    elide: Text.ElideRight
                }

                Label {
                    width: parent.width
                    text: Notifications.title
                    color: Theme.island.fg
                    font.pixelSize: 19
                    font.bold: true
                    elide: Text.ElideRight
                }

                Label {
                    width: parent.width
                    visible: Notifications.message.length > 0
                    text: Notifications.message
                    color: Theme.island.muted
                    font.pixelSize: 12
                    elide: Text.ElideRight
                }
            }

            // Contestar y rechazar SON las acciones de la notificación. Esto no
            // habla con BlueFerry: invoca lo que BlueFerry mandó, y el iPhone
            // se entera por el mismo camino por el que avisó.
            Column {
                id: buttons

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                spacing: 10

                Rectangle {
                    width: 132
                    height: 38
                    radius: 19
                    color: answerHover.hovered ? "#3ae168" : "#30d158"

                    Behavior on color { ColorAnimation { duration: Theme.motion.duration } }

                    Label {
                        anchors.centerIn: parent
                        text: "Contestar"
                        color: "#06220f"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    HoverHandler {
                        id: answerHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: Notifications.invoke(root.action("answer"))
                    }
                }

                Rectangle {
                    width: 132
                    height: 38
                    radius: 19
                    color: declineHover.hovered ? "#ff564f" : "#ff453a"

                    Behavior on color { ColorAnimation { duration: Theme.motion.duration } }

                    Label {
                        anchors.centerIn: parent
                        text: "Rechazar"
                        color: "#2b0906"
                        font.pixelSize: 13
                        font.bold: true
                    }

                    HoverHandler {
                        id: declineHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        onTapped: Notifications.invoke(root.action("decline"))
                    }
                }
            }
        }
    }

    // ── notificación, plegada ─────────────────────────────────────
    property Component toastClosed: Component {
        Item {
            anchors.fill: parent

            // Toda la píldora es la acción por defecto, cuando la hay. En un
            // mensaje del iPhone eso abre la conversación en BlueFerry.
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

            Label {
                id: who

                anchors.left: badge.right
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter

                // Se queda con lo que necesite, pero nunca más de la mitad: un
                // nombre largo no puede comerse el mensaje entero.
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

                // Texto plano: el servidor anuncia `bodyMarkupSupported: false`.
                // Lo que venía escapado ya lo desescapó el dominio.
                textFormat: Text.PlainText
                elide: Text.ElideRight
            }
        }
    }

    // ── notificación, desplegada ──────────────────────────────────
    property Component toastOpen: Component {
        Item {
            id: card

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

                // El remitente. Oculto cuando no hay: una notificación de
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
                    maximumLineCount: Notifications.replyable ? 2 : 3
                    elide: Text.ElideRight
                }
            }

            // ── responder ─────────────────────────────────────────
            //
            // Solo en mensajes: BlueFerry sabe mandar SMS e iMessage, no un
            // WhatsApp. Y solo si el puente está vivo.
            Rectangle {
                id: composer

                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                visible: Notifications.replyable && Phone.available
                height: 40
                radius: 20
                color: Theme.island.track

                // El campo pide el teclado al hacer clic, y la ventana lo tiene
                // en modo `OnDemand`, así que mientras no lo toques las teclas
                // siguen yendo a tu aplicación.
                TextInput {
                    id: field

                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    anchors.right: sendButton.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter

                    color: Theme.island.fg
                    font.pixelSize: 13

                    clip: true
                    selectByMouse: true
                    inputMethodHints: Qt.ImhNoPredictiveText

                    // Enter manda. Shift+Enter no hace nada aquí: una respuesta
                    // rápida es de una línea; lo demás, en el cliente.
                    onAccepted: card.send()

                    Label {
                        anchors.verticalCenter: parent.verticalCenter
                        visible: field.text.length === 0 && !field.activeFocus
                        text: "Responder a " + Notifications.title
                        color: Theme.island.muted
                        font.pixelSize: 13
                    }
                }

                Rectangle {
                    id: sendButton

                    anchors.right: parent.right
                    anchors.rightMargin: 5
                    anchors.verticalCenter: parent.verticalCenter

                    width: 30
                    height: 30
                    radius: 15

                    readonly property bool armed: field.text.trim().length > 0
                                                  && !Phone.sending

                    color: sendButton.armed
                        ? (sendHover.hovered ? "#4b9bff" : "#0a84ff")
                        : Qt.rgba(1, 1, 1, 0.12)

                    Behavior on color { ColorAnimation { duration: Theme.motion.duration } }

                    Label {
                        anchors.centerIn: parent
                        text: Phone.sending ? "\uf110" : "\uf1d8"
                        color: Theme.island.fg
                        font.family: Theme.font.mono
                        font.pixelSize: 13
                    }

                    HoverHandler {
                        id: sendHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    TapHandler {
                        enabled: sendButton.armed
                        onTapped: card.send()
                    }
                }
            }

            function send(): void {
                if (field.text.trim().length === 0 || Phone.sending)
                    return;

                Phone.reply(Notifications.title, field.text);
            }

            // Mandado: se limpia el campo y la isla se va. No se queda un
            // "enviado ✓" porque el mensaje ya aparece en la conversación.
            Connections {
                target: Phone

                function onSent(recipient) {
                    field.text = "";
                    Notifications.dismissCurrent();
                }
            }

            Label {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                visible: Phone.lastError.length > 0 && Notifications.replyable
                text: Phone.lastError
                color: "#ff453a"
                font.pixelSize: 11
                elide: Text.ElideRight
            }

            // Las acciones de la aplicación, y al final el descarte, que es
            // nuestro y siempre está. Se esconden cuando hay campo de respuesta:
            // no caben los dos y la respuesta es lo que querías.
            Row {
                anchors.right: parent.right
                anchors.bottom: parent.bottom

                visible: !composer.visible
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

                        Behavior on color { ColorAnimation { duration: Theme.motion.duration } }

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

                    Behavior on color { ColorAnimation { duration: Theme.motion.duration } }

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