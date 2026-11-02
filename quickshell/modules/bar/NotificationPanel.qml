// El panel de notificaciones: lo que va dentro del borde derecho cuando
// engorda (FrameWindow, hueco `notificationPanel`).
//
//   arriba    "Notificaciones" y "Borrar todo"
//   en medio  el historial, de la más nueva a la más vieja
//   abajo     No molestar
//
// Mide lo que le da el marco: todo el alto debajo de la pestaña y el ancho
// del panel (Theme.frame.notificationsWidth). El aire de los lados lo pone él.
//
// ── ¿Por qué ScriptModel y no el arreglo directo? ────────────────────────
//
// `Notifications.history` es un arreglo NUEVO cada vez que algo cambia (llega
// una, se descarta otra). Puesto tal cual como modelo, el Repeater borraría y
// volvería a crear todas las tarjetas en cada cambio: si estabas escribiendo
// una respuesta y llega otra notificación, perderías el texto y el foco.
//
// ScriptModel compara la lista nueva con la anterior y solo agrega o quita lo
// que cambió. Por eso el modelo son los ids (texto: dos ids iguales son la
// misma tarjeta) y cada tarjeta busca su entrada en `byId`, que sí se
// recalcula: si la app cambia el texto, la tarjeta se entera sin recrearse.

import QtQuick
import Quickshell
import qs.core.theme
import qs.core.components.atoms
import qs.core.components.molecules
import qs.domain.notifications
import qs.domain.time

Item {
    id: root

    // Se tocó una tarjeta que abrió algo: quien lo usa cierra el panel.
    signal opened()

    readonly property int inset: Theme.frame.inset

    readonly property var byId: {
        const map = {};
        const list = Notifications.history;
        for (let i = 0; i < list.length; ++i) {
            const entry = list[i];
            if (entry && entry.source)
                map[String(entry.source.id)] = entry;
        }
        return map;
    }

    // "ahora", "hace 5 min", "hace 2 h", "ayer"… Las que se reemitieron al
    // recargar no tienen hora: sin texto.
    function ago(arrived, now): string {
        if (!arrived)
            return "";

        const minutes = Math.floor((now - arrived) / 60000);
        if (minutes < 1)
            return "ahora";
        if (minutes < 60)
            return "hace " + minutes + " min";

        const hours = Math.floor(minutes / 60);
        if (hours < 24)
            return "hace " + hours + " h";
        if (hours < 48)
            return "ayer";
        return "hace " + Math.floor(hours / 24) + " d";
    }

    // ── Arriba ──
    Item {
        id: header

        x: root.inset
        y: 12
        width: parent.width - root.inset * 2
        height: 34

        Label {
            anchors.left: parent.left
            anchors.leftMargin: 2
            anchors.verticalCenter: parent.verticalCenter
            text: "Notificaciones"
            color: Theme.glass.content
            font.pixelSize: Theme.font.large
            font.weight: Font.Bold
        }

        ChipButton {
            anchors.right: parent.right
            anchors.verticalCenter: parent.verticalCenter
            visible: Notifications.count > 0
            text: "Borrar todo"
            onClicked: Notifications.dismissAll()
        }
    }

    // ── En medio ──
    //
    // Un Flickable con una columna, y no un ListView. Un ListView le pasa el
    // foco a su fila "actual", y al llegar una notificación la actual pasa a
    // ser la nueva de arriba: el campo donde escribías se quedaba sin foco a
    // media palabra. La columna no tiene fila actual, así que no toca el foco.
    Flickable {
        id: list

        x: root.inset
        anchors.top: header.bottom
        anchors.topMargin: 8
        anchors.bottom: footer.top
        anchors.bottomMargin: 10
        width: parent.width - root.inset * 2

        clip: true
        contentWidth: width
        contentHeight: cards.height
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: cards

            width: list.width
            spacing: 8

            // Entrar con un desvanecido corto, y las demás se recorren.
            add: Transition {
                NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 200 }
            }
            move: Transition {
                NumberAnimation { properties: "y"; duration: 220; easing.type: Easing.OutCubic }
            }

            Repeater {
                model: ScriptModel {
                    values: Notifications.history.map(entry => String(entry.source.id))
                }

                delegate: NotificationCard {
                    id: card

                    required property var modelData

                    width: cards.width
                    entry: root.byId[card.modelData] ?? null
                    when: root.ago(card.entry ? card.entry.arrived : 0, Clock.now.getTime())

                    onOpened: root.opened()
                }
            }
        }
    }

    Column {
        anchors.centerIn: list
        visible: Notifications.count === 0
        spacing: 6

        Icon {
            anchors.horizontalCenter: parent.horizontalCenter
            icon: Theme.systemIcons.bell
            size: 22
            color: Theme.glass.contentMuted
        }

        Label {
            anchors.horizontalCenter: parent.horizontalCenter
            text: "Sin notificaciones"
            color: Theme.glass.contentMuted
            font.pixelSize: 13
        }
    }

    // ── Abajo: No molestar ──
    Rectangle {
        id: footer

        x: root.inset
        anchors.bottom: parent.bottom
        anchors.bottomMargin: root.inset
        width: parent.width - root.inset * 2
        height: 52
        radius: 20
        color: Qt.rgba(1, 1, 1, 0.10)

        Rectangle {
            id: moon

            x: 12
            anchors.verticalCenter: parent.verticalCenter
            width: 28
            height: 28
            radius: 14
            color: DoNotDisturb.active ? Theme.colors.accent : Qt.rgba(1, 1, 1, 0.16)

            Icon {
                anchors.centerIn: parent
                icon: Theme.systemIcons.moon
                size: 14
                color: Theme.glass.content
            }
        }

        Label {
            anchors.left: moon.right
            anchors.leftMargin: 10
            anchors.right: toggle.left
            anchors.rightMargin: 10
            anchors.verticalCenter: parent.verticalCenter
            text: "No molestar"
            color: Theme.glass.content
            font.pixelSize: 13
            font.weight: Font.DemiBold
        }

        ToggleSwitch {
            id: toggle

            anchors.right: parent.right
            anchors.rightMargin: 12
            anchors.verticalCenter: parent.verticalCenter
            checked: DoNotDisturb.active
            offColor: Theme.glass.control
            onToggled: DoNotDisturb.toggle()
        }
    }
}
