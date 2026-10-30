// Tus teclados Bluetooth en la isla (el Apple o cualquier otro), como en el
// iPhone y la Mac:
//   - al conectarlo, su nombre y su batería un momento;
//   - cuando se queda sin batería (20 % y otra vez 10 %), el aviso en rojo.
// Los de cable o receptor no avisan: no hay "conexión" que anunciar, y su
// batería, si la tienen, no llega por Bluetooth.
//
// Se va solo. Va con la misma prioridad que los AirPods (70): por encima del
// volumen y del brillo, por debajo de las notificaciones. Se ve igual que el
// de los AirPods (DevicePeek) y su ancho sigue al texto con la misma cuenta
// (PeekWidth).

import QtQuick
import qs.core.theme
import qs.core.components.molecules
import qs.core.utils
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
        if (root.reason === "low" && !root.charging)
            return Theme.systemIcons.batteryLevel.warning;
        return Theme.batteryIcon(root.battery, root.charging);
    }

    readonly property string detailText: root.battery >= 0
        ? Math.round(root.battery * 100) + "%"
        : "Conectado"

    PeekWidth {
        id: measure
        title: root.title
        detailText: root.detailText
        hasDetailIcon: root.detailIcon !== ""
    }

    contentWidth: measure.width

    view: Component {
        DevicePeek {
            anchors.fill: parent
            glyph: Theme.systemIcons.device.keyboard
            title: root.title
            detailIcon: root.detailIcon
            detailText: root.detailText
            alert: root.low
            dim: root.battery < 0
        }
    }
}
