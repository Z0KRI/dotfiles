// Tus AirPods, como en el iPhone: al conectarlos la isla se ensancha un
// momento con su nombre y la batería, y al cambiar el control de ruido (desde
// el Centro de control o apretando el tallo) enseña el modo nuevo.
//
// Se va solo, como el volumen. Va por encima de él (70 contra 60) y por
// debajo de las notificaciones.
//
// Se ve igual que el aviso de un teclado (DevicePeek), y su ancho sigue al
// texto con la misma cuenta (PeekWidth).

import QtQuick
import qs.core.theme
import qs.core.components.molecules
import qs.core.utils
import qs.domain.airpods

IslandOccupant {
    id: root

    name: "airpods"
    priority: 70

    ephemeral: true
    timeout: 3200

    contentHeight: Theme.island.closedHeight

    // Qué enseña a la derecha: "battery" al conectarse, "mode" al cambiar de
    // modo.
    property string reason: "battery"

    function show(reason): void {
        root.reason = reason;
        root.poke();
    }

    // Al arrancar la shell no se avisa de que ya estaban conectados: Bluetooth
    // y LibrePods publican su estado de golpe y no es ninguna novedad.
    property bool armed: false

    Timer {
        interval: 2500
        running: true
        onTriggered: root.armed = true
    }

    // Recién conectados, LibrePods tarda unos segundos en leer el modo de
    // verdad (antes marca el primero de su lista). Ese cambio no es tuyo, y
    // el aviso de conexión ya está en pantalla: no se anuncia.
    Timer {
        id: settling
        interval: 6000
    }

    Connections {
        target: AirPods

        function onConnectedChanged() {
            if (!AirPods.connected)
                return;

            settling.restart();
            if (root.armed)
                root.show("battery");
        }

        // LibrePods tarda un poco en leer la batería: cuando llega, el aviso
        // de conexión se queda lo suyo para que se alcance a ver.
        function onPiecesChanged() {
            if (root.active && root.reason === "battery")
                root.poke();
        }

        // Lo mismo si LibrePods arranca con ellos ya conectados.
        function onControllableChanged() {
            settling.restart();
        }

        function onModeChanged() {
            if (root.armed && AirPods.connected && !settling.running && AirPods.mode !== "")
                root.show("mode");
        }
    }

    // ── lo que enseña ─────────────────────────────────────────────
    //
    // Derecha: el modo nuevo, o la batería (la del AirPod más bajo; el
    // estuche no cuenta). Sin batería todavía, solo "Conectados".
    readonly property bool showsMode: root.reason === "mode" && AirPods.mode !== ""
    readonly property bool hasBattery: AirPods.pieces.some(p => p.id !== "case")
    readonly property bool charging: AirPods.pieces.some(p => p.id !== "case" && p.charging)
    readonly property bool lowBattery: !root.showsMode && root.hasBattery && !root.charging
                                       && AirPods.lowest <= 0.2

    readonly property string detailIcon: {
        if (root.showsMode)
            return Theme.systemIcons.airpods[AirPods.mode];
        if (!root.hasBattery)
            return "";
        return Theme.batteryIcon(AirPods.lowest, root.charging);
    }

    readonly property string detailText: {
        if (root.showsMode)
            return AirPods.modes.find(m => m.id === AirPods.mode)?.short ?? "";
        if (root.hasBattery)
            return Math.round(AirPods.lowest * 100) + "%";
        return "Conectados";
    }

    PeekWidth {
        id: measure
        title: AirPods.name
        detailText: root.detailText
        hasDetailIcon: root.detailIcon !== ""
    }

    contentWidth: measure.width

    view: Component {
        DevicePeek {
            anchors.fill: parent
            glyph: Theme.systemIcons.device.headphones
            title: AirPods.name
            detailIcon: root.detailIcon
            detailText: root.detailText
            alert: root.lowBattery
            dim: !root.showsMode && !root.hasBattery
        }
    }
}
