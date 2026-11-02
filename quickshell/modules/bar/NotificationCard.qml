// Una notificación del historial, como tarjeta del panel lateral.
//
//   arriba    el símbolo de la app en un círculo, "App · iPhone" y hace cuánto
//             llegó (al pasar el mouse, una × para descartarla)
//   en medio  quién escribe y el mensaje
//   abajo     responder, solo en los mensajes del iPhone (SMS / iMessage)
//
// Tocarla hace su acción "default" (abrir la conversación, la app) y avisa con
// `opened`, para que el panel se cierre como en macOS. Las que no tienen esa
// acción no hacen nada al tocarlas.
//
// La tarjeta NO guarda la entrada: recibe `entry` ya resuelta por el panel.
// Así, si la app reemplaza el texto de su notificación, la tarjeta se
// actualiza sin volver a crearse (y sin perder lo que llevas escrito).

import QtQuick
import Quickshell.Widgets
import qs.core.theme
import qs.core.components.atoms
import qs.domain.notifications
import qs.domain.phone

Rectangle {
    id: root

    property var entry: null

    // "hace 5 min". Lo calcula el panel con su reloj.
    property string when: ""

    signal opened()

    readonly property bool hasEntry: root.entry !== null

    // El círculo del símbolo: verde para Mensajes y rojo para las llamadas,
    // como en el iPhone; gris para los avisos del teléfono; para lo demás, el
    // mismo blanco tenue de los mosaicos.
    readonly property color tint: {
        switch (root.entry ? root.entry.kind : "") {
        case "phone-message": return Theme.accents.green.light;
        case "missed-call":
        case "call": return Theme.accents.red.light;
        case "phone-battery": return "#636366";
        default: return Theme.glass.tileHover;
        }
    }

    readonly property string picture: root.entry ? String(root.entry.image || "") : ""
    readonly property string appIcon: root.entry ? String(root.entry.icon || "") : ""

    readonly property string source: {
        if (!root.entry)
            return "";
        const app = String(root.entry.appName || "");
        return root.entry.fromPhone && app !== "iPhone" ? app + " · iPhone" : app;
    }

    // Quién escribe. Si no hay nadie detrás (un aviso del sistema), el título
    // es el mismo nombre de la app y no se repite.
    readonly property string headline: {
        if (!root.entry)
            return "";
        const title = String(root.entry.title || "");
        return title === String(root.entry.appName || "") ? "" : title;
    }

    readonly property string message: root.entry ? String(root.entry.message || "").trim() : ""

    readonly property bool canReply: root.hasEntry && !!root.entry.replyable && Phone.available

    readonly property int lead: 34   // del borde al texto: el círculo y su aire

    implicitHeight: body.implicitHeight + 24
    radius: 20
    color: hover.hovered ? Qt.rgba(1, 1, 1, 0.14) : Qt.rgba(1, 1, 1, 0.10)

    Behavior on color {
        ColorAnimation { duration: 120 }
    }

    HoverHandler {
        id: hover
    }

    // El fondo de la tarjeta: tocarla la abre. Va primero para quedar debajo:
    // el campo de respuesta y los botones se llevan sus clics antes.
    MouseArea {
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            if (Notifications.openEntry(root.entry))
                root.opened();
        }
    }

    Column {
        id: body

        x: 12
        y: 12
        width: parent.width - 12 - 14
        spacing: 8

        // ── Arriba: la app y la hora ──
        Item {
            width: parent.width
            height: 26

            ClippingRectangle {
                id: badge

                width: 26
                height: 26
                radius: 13
                color: root.tint

                AppBadge {
                    anchors.centerIn: parent
                    image: root.picture
                    icon: root.appIcon
                    glyph: root.entry ? String(root.entry.glyph || "") : ""
                    fontFamily: root.entry ? String(root.entry.glyphFamily || "") : ""
                    color: "#ffffff"
                    size: root.picture !== "" ? 26 : root.appIcon !== "" ? 18 : 15
                }
            }

            Label {
                anchors.left: badge.right
                anchors.leftMargin: 8
                anchors.right: corner.left
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: root.source
                color: Theme.glass.contentMuted
                font.pixelSize: 12
            }

            // La hora, o la × mientras el mouse está encima.
            Item {
                id: corner

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(timeLabel.implicitWidth, 22)
                height: 22

                Label {
                    id: timeLabel

                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: !hover.hovered
                    text: root.when
                    color: Theme.glass.contentMuted
                    font.pixelSize: 11
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: hover.hovered
                    width: 22
                    height: 22
                    radius: 11
                    color: closeHover.hovered ? Qt.rgba(1, 1, 1, 0.26) : Qt.rgba(1, 1, 1, 0.16)

                    Icon {
                        anchors.centerIn: parent
                        icon: Theme.systemIcons.xMark
                        size: 11
                        color: Theme.glass.content
                    }

                    HoverHandler {
                        id: closeHover
                        cursorShape: Qt.PointingHandCursor
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: Notifications.dismissEntry(root.entry)
                    }
                }
            }
        }

        // ── En medio: quién y qué ──
        Column {
            x: root.lead
            width: parent.width - root.lead
            spacing: 2

            Label {
                width: parent.width
                visible: text !== ""
                text: root.headline
                color: Theme.glass.content
                font.pixelSize: 13
                font.weight: Font.DemiBold
            }

            Label {
                width: parent.width
                visible: text !== ""
                text: root.message
                color: Qt.rgba(1, 1, 1, 0.85)
                font.pixelSize: 13
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
            }
        }

        // ── Abajo: responder ──
        //
        // Lo mismo que en la isla: BlueFerry busca la conversación por el
        // nombre de quien escribe y manda ahí. Enter manda.
        Item {
            id: composer

            x: root.lead
            width: parent.width - root.lead
            height: 30
            visible: root.canReply

            // Esta tarjeta mandó algo y espera la respuesta del puente.
            property bool asked: false

            function send(): void {
                const text = field.text.trim();
                if (text.length === 0 || Phone.sending)
                    return;

                composer.asked = true;
                Phone.reply(root.entry.title, text);
            }

            Rectangle {
                anchors.left: parent.left
                anchors.right: sendButton.left
                anchors.rightMargin: 6
                height: parent.height
                radius: height / 2
                color: Qt.rgba(0, 0, 0, 0.35)
                border.width: 1
                border.color: field.activeFocus ? Qt.rgba(1, 1, 1, 0.32) : Qt.rgba(1, 1, 1, 0.14)

                TextInput {
                    id: field

                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter

                    color: Theme.glass.content
                    font.family: Theme.font.ui
                    font.pixelSize: 12
                    clip: true
                    selectByMouse: true
                    inputMethodHints: Qt.ImhNoPredictiveText

                    onAccepted: composer.send()

                    // Esc suelta el campo: el teclado vuelve a tu ventana en
                    // cuanto mueves el foco (la ventana del marco lo pide
                    // solo al hacer clic).
                    Keys.onEscapePressed: field.focus = false

                    Label {
                        anchors.fill: parent
                        verticalAlignment: Text.AlignVCenter
                        visible: field.text.length === 0 && !field.activeFocus
                        text: "Responder…"
                        color: Theme.glass.contentMuted
                        font.pixelSize: 12
                    }
                }
            }

            Rectangle {
                id: sendButton

                readonly property bool ready: field.text.trim().length > 0 && !Phone.sending

                anchors.right: parent.right
                width: 30
                height: 30
                radius: 15
                color: sendButton.ready ? Theme.colors.accent : Qt.rgba(1, 1, 1, 0.12)

                Icon {
                    anchors.centerIn: parent
                    icon: Phone.sending && composer.asked ? Theme.systemIcons.sending : Theme.systemIcons.send
                    size: 14
                    color: Theme.glass.content
                }

                MouseArea {
                    anchors.fill: parent
                    enabled: sendButton.ready
                    cursorShape: Qt.PointingHandCursor
                    onClicked: composer.send()
                }
            }

            Connections {
                target: Phone
                enabled: composer.asked

                // Ya respondiste: la tarjeta sobra, igual que en la isla.
                function onSent(recipient) {
                    composer.asked = false;
                    field.text = "";
                    Notifications.dismissEntry(root.entry);
                }
            }
        }

        // Si no se pudo mandar, debajo del campo.
        Label {
            x: root.lead
            width: parent.width - root.lead
            visible: composer.visible && composer.asked && !Phone.sending && Phone.lastError.length > 0
            text: Phone.lastError
            color: "#ff7b72"
            font.pixelSize: 11
            wrapMode: Text.Wrap
        }
    }
}
