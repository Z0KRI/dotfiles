// Lo que acaba de llegar. Prioridad por encima del volumen y del reproductor:
// una notificación interrumpe, es su trabajo. Y una llamada interrumpe a la
// notificación.
//
// Cuatro vistas, no dos. Una llamada entrante y un mensaje no se parecen en
// nada: la llamada se abre sola y espera una decisión, el mensaje espera una
// respuesta. Se eligen con `Notifications.kind`, que ya viene tipado — aquí no
// hay un solo `split` ni un emoji.
//
// Las del mensaje son de la familia del reproductor: plegada, una línea que
// mide lo que su texto; desplegada, la imagen grande a la izquierda y el
// texto a su lado (CoverArt y las medidas `open*` de Theme.island).
//
// Regla de toda vista de la isla: HoverHandler y TapHandler, nunca un MouseArea
// con `hoverEnabled`. Un MouseArea que acepta hover se lo queda, el detector de
// la superficie deja de verlo y la tarjeta se cierra justo al ir a pulsar.

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.domain.notifications
import qs.domain.phone
import qs.domain.settings

IslandOccupant {
    id: root

    name: "notification"

    // Una llamada no la desbanca nada.
    priority: root.isCall ? 120 : 80

    active: Notifications.hasCurrent

    readonly property bool isCall: Notifications.kind === "call"

    contentWidth: root.isCall ? 280 : root.toastWidth
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

    // Red de seguridad: una llamada no suena minuto y medio. Si para entonces
    // nadie cerró su notificación (BlueFerry la cierra al dejar de sonar), se
    // suelta la isla en vez de quedarse con una llamada que ya no existe.
    Timer {
        interval: 90000
        running: root.active && Notifications.holds
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

    // Busca una acción por su identificador. Cada botón de la llamada quiere
    // la suya, no la lista: cuáles son lo dice Notifications.answerAction y
    // declineAction (las de --calls o las del iPhone).
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
                glyph: Notifications.glyph
                fontFamily: Notifications.glyphFamily
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

            // A la derecha: Contestar y Rechazar, o, si la llamada llegó sin
            // botones, Descartar y dónde se arregla eso.
            Item {
                id: buttons

                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter

                width: 132
                height: Notifications.answerable ? answerColumn.height : onPhone.height

                // Contestar y rechazar SON las acciones de la notificación.
                // Esto no habla con BlueFerry: invoca lo que BlueFerry mandó,
                // y el iPhone se entera por el mismo camino por el que avisó.
                Column {
                    id: answerColumn
                    visible: Notifications.answerable
                    spacing: 10

                    IslandButton {
                        width: 132
                        height: 38
                        text: "Contestar"
                        tint: "#30d158"
                        textColor: "#06220f"
                        fontSize: 13
                        bold: true

                        onTapped: {
                            // La de --calls se queda en la isla como llamada
                            // en curso (CallOccupant).
                            if (Notifications.answerAction === "answer")
                                Calls.expectAnswer();
                            Notifications.invoke(root.action(Notifications.answerAction));
                        }
                    }

                    IslandButton {
                        width: 132
                        height: 38
                        text: "Rechazar"
                        tint: "#ff453a"
                        textColor: "#2b0906"
                        fontSize: 13
                        bold: true
                        onTapped: Notifications.invoke(root.action(Notifications.declineAction))
                    }
                }

                // Suena, pero el iPhone no mandó con qué contestar.
                Column {
                    id: onPhone

                    visible: !Notifications.answerable
                    width: parent.width
                    spacing: 8

                    IslandButton {
                        width: parent.width
                        height: 38
                        text: "Descartar"
                        fontSize: 13
                        bold: true
                        onTapped: Notifications.dismissCurrent()
                    }

                    Label {
                        width: parent.width
                        horizontalAlignment: Text.AlignHCenter
                        wrapMode: Text.WordWrap
                        elide: Text.ElideNone
                        text: "Contéstala en el iPhone. Para contestar aquí: Ajustes › iPhone"
                        color: hintHover.hovered ? Theme.island.fg : Theme.island.muted
                        font.pixelSize: 11

                        HoverHandler {
                            id: hintHover
                            cursorShape: Qt.PointingHandCursor
                        }

                        TapHandler {
                            onTapped: SettingsControl.open("iphone")
                        }
                    }
                }
            }
        }
    }

    // ── notificación, plegada ─────────────────────────────────────
    //
    // Una línea, como el reproductor plegado: la foto chica (o el logo de la
    // app), quién escribe y el mensaje. El mensaje va en UNA línea
    // (`preview`): con sus saltos de línea, un Text pinta una por salto, no
    // las corta con "…", y la de abajo se sale de la isla.
    property Component toastClosed: Component {
        Item {
            anchors.fill: parent

            // Toda la píldora es la acción por defecto, cuando la hay. En un
            // mensaje del iPhone eso abre la conversación en BlueFerry.
            TapHandler {
                enabled: Notifications.hasDefaultAction
                onTapped: Notifications.invokeDefault()
            }

            CoverArt {
                id: badge

                anchors.left: parent.left
                anchors.leftMargin: root.toastEdge
                anchors.verticalCenter: parent.verticalCenter

                width: Theme.island.artClosed
                height: Theme.island.artClosed
                radius: Theme.island.artClosedRadius

                // Sin cuadro gris: sin foto, el logo de la app en blanco, como
                // el ícono de la app en la isla del iPhone.
                color: "transparent"
                source: Notifications.image
                icon: Notifications.icon
                iconScale: 1
                glyph: Notifications.glyph
                glyphFamily: Notifications.glyphFamily
                glyphSize: 15
                glyphColor: Theme.island.fg
            }

            Label {
                id: who

                anchors.left: badge.right
                anchors.leftMargin: root.toastGap
                anchors.verticalCenter: parent.verticalCenter

                // Se queda con lo que necesite, pero con mensaje nunca más de
                // la mitad: un nombre largo no puede comerse el mensaje entero.
                width: Math.min(who.implicitWidth,
                                Notifications.preview.length > 0
                                    ? parent.width * 0.45
                                    : parent.width - who.x - root.toastEnd)

                text: Notifications.headline
                color: Theme.island.fg
                font.pixelSize: root.toastText
                font.weight: Font.DemiBold
                maximumLineCount: 1
            }

            Label {
                anchors.left: who.right
                anchors.leftMargin: root.toastSplit
                anchors.right: parent.right
                anchors.rightMargin: root.toastEnd
                anchors.verticalCenter: parent.verticalCenter

                text: Notifications.preview
                color: Theme.island.muted
                font.pixelSize: root.toastText

                // Texto plano: el servidor anuncia `bodyMarkupSupported: false`.
                // Lo que venía escapado ya lo desescapó el dominio.
                textFormat: Text.PlainText
                maximumLineCount: 1
                elide: Text.ElideRight
            }
        }
    }

    // ── notificación, desplegada: como el reproductor ─────────────
    //
    // La misma familia que el reproductor desplegado (las medidas salen de
    // Theme.island): la imagen grande a la izquierda —la foto de quien
    // escribe con su halo, o el ícono o el logo de la app en su cuadro— y a
    // su lado, dentro de su altura: quién escribe, la app en la esquina, el
    // mensaje y, abajo, los botones o el campo para responder.
    property Component toastOpen: Component {
        Item {
            id: card

            anchors.fill: parent
            anchors.topMargin: Theme.island.openTopRadius
            anchors.leftMargin: Theme.island.openStart
            anchors.rightMargin: Theme.island.openEnd
            anchors.bottomMargin: Theme.island.openBottom

            CoverArt {
                id: art

                anchors.left: parent.left
                anchors.verticalCenter: parent.verticalCenter

                width: Theme.island.artOpen
                height: Theme.island.artOpen
                radius: Theme.island.artOpenRadius
                decodeSize: Theme.island.artOpen * 2

                source: Notifications.image
                icon: Notifications.icon
                glyph: Notifications.glyph
                glyphFamily: Notifications.glyphFamily
                glyphSize: 52
                glow: true
            }

            Item {
                id: side

                anchors.left: art.right
                anchors.leftMargin: Theme.island.openGap
                anchors.right: parent.right
                anchors.top: art.top
                anchors.bottom: art.bottom
            }

            // La app de verdad ("Gmail", no "BlueFerry"), en la esquina con
            // su logo: donde el reproductor pone el programa que suena. Si no
            // hay nadie detrás, la app ya es el título y aquí sobra.
            Row {
                id: source

                anchors.right: side.right
                anchors.top: side.top
                anchors.topMargin: 2

                visible: Notifications.title.length > 0 && Notifications.appName.length > 0
                spacing: 5

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Notifications.glyph
                    color: Theme.island.muted
                    font.family: Notifications.glyphFamily
                    font.pixelSize: Theme.island.openCaption
                }

                Label {
                    id: sourceName

                    // Un nombre de app largo no se come el título.
                    width: Math.min(sourceName.implicitWidth, side.width * 0.35)
                    text: Notifications.appName
                    color: Theme.island.muted
                    font.pixelSize: Theme.island.openCaption
                    maximumLineCount: 1
                }
            }

            Label {
                id: headline

                anchors.left: side.left
                anchors.right: source.visible ? source.left : side.right
                anchors.rightMargin: source.visible ? 14 : 0
                anchors.top: side.top

                text: Notifications.headline
                color: Theme.island.fg
                font.pixelSize: Theme.island.openTitle
                font.weight: Font.DemiBold
                maximumLineCount: 1
            }

            // El mensaje, hasta donde empiezan los botones. `Text.Wrap` y no
            // `WordWrap`: una palabra más ancha que la isla (un enlace) se
            // parte en vez de salirse por la derecha.
            Label {
                anchors.left: side.left
                anchors.right: side.right
                anchors.top: headline.bottom
                anchors.topMargin: 3

                text: Notifications.message
                color: Theme.island.muted
                font.pixelSize: Theme.island.openSubtitle

                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                maximumLineCount: 3
                elide: Text.ElideRight
            }

            // ── responder ─────────────────────────────────────────
            //
            // Solo en mensajes: BlueFerry sabe mandar SMS e iMessage, no un
            // WhatsApp. Y solo si el puente está vivo.
            Rectangle {
                id: composer

                anchors.left: side.left
                anchors.right: side.right
                anchors.bottom: side.bottom

                visible: Notifications.replyable && Phone.available
                height: 36
                radius: height / 2
                color: Theme.island.track

                // El campo pide el teclado al hacer clic, y la ventana lo tiene
                // en modo `OnDemand`, así que mientras no lo toques las teclas
                // siguen yendo a tu aplicación.
                TextInput {
                    id: field

                    anchors.left: parent.left
                    anchors.leftMargin: 14
                    anchors.right: sendButton.left
                    anchors.rightMargin: 10
                    anchors.verticalCenter: parent.verticalCenter

                    color: Theme.island.fg
                    font.family: Theme.font.ui
                    font.pixelSize: Theme.island.openSubtitle

                    clip: true
                    selectByMouse: true
                    inputMethodHints: Qt.ImhNoPredictiveText

                    // Enter manda. Shift+Enter no hace nada aquí: una respuesta
                    // rápida es de una línea; lo demás, en el cliente.
                    onAccepted: card.send()

                    Label {
                        anchors.left: parent.left
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        visible: field.text.length === 0 && !field.activeFocus
                        text: "Responder a " + Notifications.title
                        color: Theme.island.muted
                        font.pixelSize: Theme.island.openSubtitle
                    }
                }

                IslandButton {
                    id: sendButton

                    anchors.right: parent.right
                    anchors.rightMargin: 4
                    anchors.verticalCenter: parent.verticalCenter

                    width: 28
                    height: 28

                    // Azul cuando hay algo que mandar, como en Mensajes.
                    enabled: field.text.trim().length > 0 && !Phone.sending
                    tint: sendButton.enabled ? "#0a84ff" : "transparent"
                    icon: Phone.sending ? Theme.systemIcons.sending : Theme.systemIcons.send
                    iconSize: 14

                    onTapped: card.send()
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

            // Si no se pudo mandar, justo encima del campo (no encima de él).
            Label {
                anchors.left: side.left
                anchors.right: side.right
                anchors.bottom: composer.top
                anchors.bottomMargin: 4

                visible: composer.visible && Phone.lastError.length > 0
                text: Phone.lastError
                color: "#ff453a"
                font.pixelSize: Theme.island.openCaption
                maximumLineCount: 1
            }

            // Las acciones de la aplicación y, al final, el descarte, que es
            // nuestro y siempre está; ese sin fondo, como anterior y siguiente
            // en el reproductor, para que lo de la app sea lo que destaca. Se
            // esconden cuando hay campo de respuesta: no caben los dos y la
            // respuesta es lo que querías. Tres acciones como mucho: más no
            // caben a lo ancho.
            Row {
                anchors.right: side.right
                anchors.bottom: side.bottom

                visible: !composer.visible
                spacing: 8

                Repeater {
                    model: Notifications.actions.slice(0, 3)

                    IslandButton {
                        required property var modelData

                        height: 30
                        text: modelData.text
                        onTapped: Notifications.invoke(modelData)
                    }
                }

                IslandButton {
                    height: 30
                    flat: true
                    text: "Descartar"
                    textColor: Theme.island.muted
                    onTapped: Notifications.dismissCurrent()
                }
            }
        }
    }

    // ── el ancho plegado ──────────────────────────────────────────
    //
    // Lo que mide el texto, entre el ancho mínimo de la isla y el mismo tope
    // que los avisos de los AirPods; más allá, el mensaje se corta con "…".
    // Se mide aquí y no en la vista: la isla toma este ancho ANTES de cargar
    // lo de adentro.
    readonly property int toastEdge: 7      // borde → foto
    readonly property int toastGap: 8       // foto → nombre
    readonly property int toastSplit: 7     // nombre → mensaje
    readonly property int toastEnd: 12      // mensaje → borde
    readonly property int toastText: 12

    TextMetrics {
        id: headMetrics
        font.family: Theme.font.ui
        font.pixelSize: root.toastText
        font.weight: Font.DemiBold
        text: Notifications.headline
    }

    TextMetrics {
        id: previewMetrics
        font.family: Theme.font.ui
        font.pixelSize: root.toastText
        text: Notifications.preview
    }

    readonly property int toastWidth: {
        const message = Notifications.preview.length > 0
            ? root.toastSplit + previewMetrics.advanceWidth
            : 0;
        const inner = root.toastEdge + Theme.island.artClosed + root.toastGap
                      + headMetrics.advanceWidth + message + root.toastEnd;
        const total = Math.ceil(inner) + Theme.island.closedTopRadius * 2;   // las alas

        return Math.max(Theme.island.minWidth, Math.min(Theme.island.peekMaxWidth, total));
    }
}
