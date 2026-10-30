// Tus teclados Bluetooth en la isla (el Apple o cualquier otro), como en el
// iPhone y la Mac:
//   - al conectarlo, su nombre y su batería un momento;
//   - cuando se queda sin batería (20 % y otra vez 10 %), el aviso en rojo.
// Los de cable o receptor no avisan: no hay "conexión" que anunciar, y su
// batería, si la tienen, no llega por Bluetooth.
//
// Se va solo. Va con la misma prioridad que los AirPods (70): por encima del
// volumen y del brillo, por debajo de las notificaciones. Su ancho sigue al
// texto, con la misma regla que el de los AirPods.

import QtQuick
import qs.core.theme
import qs.core.components.atoms
import qs.domain.keyboard

IslandOccupant {
    id: root

    name: "keyboard"
    priority: 70

    ephemeral: true
    timeout: 3200

    contentHeight: Theme.island.closedHeight

    // "arrived" al conectarse, "low" al quedarse sin batería.
    property string reason: "arrived"
    property var keyboard: null

    function show(reason, keyboard): void {
        root.reason = reason;
        root.keyboard = keyboard;
        root.poke();
    }

    Connections {
        target: Keyboards

        function onArrived(keyboard) {
            root.show("arrived", keyboard);
        }

        function onLowBattery(keyboard) {
            root.show("low", keyboard);
        }

        // La batería llega un poco después de conectarse (UPower tarda en
        // leerla): el aviso de conexión se queda lo suyo para que se alcance
        // a ver.
        function onBluetoothChanged() {
            if (root.active && root.reason === "arrived" && root.battery >= 0)
                root.poke();
        }
    }

    // Lo de ahora, no lo del momento del aviso: si la batería llegó después,
    // ya sale.
    readonly property var live: root.keyboard
        ? (Keyboards.bluetooth.find(k => k.address === root.keyboard.address) ?? root.keyboard)
        : null

    readonly property real battery: root.live ? root.live.battery : -1
    readonly property bool charging: root.live ? root.live.charging : false
    readonly property bool low: root.battery >= 0 && !root.charging && root.battery <= 0.2

    readonly property string title: root.reason === "low"
        ? "Queda poca batería"
        : (root.live ? root.live.name : "Teclado")

    readonly property string detailIcon: {
        if (root.battery < 0)
            return "";
        if (root.charging)
            return Theme.systemIcons.batteryLevel.charging;
        if (root.reason === "low")
            return Theme.systemIcons.batteryLevel.warning;
        if (root.battery > 0.6)
            return Theme.systemIcons.batteryLevel.full;
        if (root.battery > 0.2)
            return Theme.systemIcons.batteryLevel.medium;
        return Theme.systemIcons.batteryLevel.low;
    }

    readonly property string detailText: root.battery >= 0
        ? Math.round(root.battery * 100) + "%"
        : "Conectado"

    // ── el ancho ──────────────────────────────────────────────────
    readonly property int edge: 12
    readonly property int glyph: 14
    readonly property int gap: 8
    readonly property int split: 16
    readonly property int textSize: 12
    readonly property int maxWidth: 460

    TextMetrics {
        id: titleMetrics
        font.family: Theme.font.ui
        font.pixelSize: root.textSize
        font.weight: Font.DemiBold
        text: root.title
    }

    TextMetrics {
        id: detailMetrics
        font.family: Theme.font.ui
        font.pixelSize: root.textSize
        text: root.detailText
    }

    contentWidth: {
        const detail = (root.detailIcon !== "" ? root.glyph + 6 : 0) + detailMetrics.advanceWidth;
        const inner = root.edge + root.glyph + root.gap + titleMetrics.advanceWidth
                      + root.split + detail + root.edge;
        const total = Math.ceil(inner) + Theme.island.closedTopRadius * 2;   // las alas
        return Math.max(Theme.island.minWidth, Math.min(root.maxWidth, total));
    }

    view: Component {
        Item {
            anchors.fill: parent

            Icon {
                id: glyph

                anchors.left: parent.left
                anchors.leftMargin: root.edge
                anchors.verticalCenter: parent.verticalCenter

                width: root.glyph
                icon: Theme.systemIcons.device.keyboard
                size: root.glyph
                color: Theme.island.fg
            }

            Label {
                anchors.left: glyph.right
                anchors.leftMargin: root.gap
                anchors.right: detail.left
                anchors.rightMargin: root.split
                anchors.verticalCenter: parent.verticalCenter

                text: root.title
                elide: Text.ElideRight
                color: Theme.island.fg
                font.pixelSize: root.textSize
                font.weight: Font.DemiBold
            }

            Row {
                id: detail

                anchors.right: parent.right
                anchors.rightMargin: root.edge
                anchors.verticalCenter: parent.verticalCenter
                spacing: 6

                Icon {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: root.detailIcon !== ""
                    width: root.glyph
                    size: root.glyph
                    icon: root.detailIcon
                    color: root.low ? Theme.colors.error : Theme.island.fg
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.detailText
                    color: root.low ? Theme.colors.error : (root.battery >= 0 ? Theme.island.fg : Theme.island.muted)
                    font.pixelSize: root.textSize
                }
            }
        }
    }
}
