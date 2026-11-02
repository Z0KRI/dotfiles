// Tu iPhone en la isla: al conectarse, su nombre y su batería un momento,
// como los AirPods y los teclados.
//
// Cuándo sale lo decide PhoneService: cuando el iPhone termina de
// conectarse, no al arrancar la shell ni tras un parpadeo de la conexión.
// Aquí solo se enseña.
//
// La batería no llega con la conexión: viaja por Bluetooth LE, que el iPhone
// abre unos segundos después del clásico (y por donde llegan también las
// notificaciones). PhoneService espera a que llegue antes de avisar, hasta
// unos segundos; si no llega, el aviso dice "Conectado", y si llega con el
// aviso en pantalla, se queda lo suyo para que se alcance a ver.
//
// Se va solo. Misma prioridad que los AirPods y el teclado (70): por encima
// del volumen y del brillo, por debajo de las notificaciones. Se ve igual que
// ellos (DevicePeek) y su ancho sigue al texto con la misma cuenta
// (PeekWidth).

import QtQuick
import qs.core.theme
import qs.core.components.molecules
import qs.core.utils
import qs.domain.phone

IslandOccupant {
    id: root

    name: "phone"
    priority: 70

    ephemeral: true
    timeout: 3200

    contentHeight: Theme.island.closedHeight

    // El iPhone del aviso, tal como estaba al llegar.
    property var phone: null

    Connections {
        target: PhoneService

        function onArrived(phone) {
            root.phone = phone;
            root.poke();
        }
    }

    // Lo de ahora, no lo del momento del aviso: si la batería llegó después,
    // ya sale. Si el iPhone se fue con el aviso en pantalla, se queda lo que
    // había.
    readonly property var live: (root.phone && PhoneService.phone
                                 && PhoneService.phone.address === root.phone.address)
                                ? PhoneService.phone : root.phone

    readonly property real battery: root.live ? root.live.battery : -1
    readonly property bool charging: root.live ? root.live.charging : false
    readonly property bool hasBattery: root.battery >= 0
    readonly property bool low: root.hasBattery && !root.charging && root.battery <= 0.2

    // Un bool solo avisa cuando de verdad cambia: esto pasa una vez, cuando
    // llega el porcentaje, y no con cada cambio de cualquier aparato.
    onHasBatteryChanged: {
        if (root.active && root.hasBattery)
            root.poke();
    }

    readonly property string title: root.live ? root.live.name : "iPhone"

    readonly property string detailIcon: root.hasBattery
        ? Theme.batteryIcon(root.battery, root.charging)
        : ""

    readonly property string detailText: root.hasBattery
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
            glyph: Theme.systemIcons.device.phone
            title: root.title
            detailIcon: root.detailIcon
            detailText: root.detailText
            alert: root.low
            dim: !root.hasBattery
        }
    }
}
