// Tus AirPods, como en el iPhone: al conectarlas la isla se ensancha un
// momento con su nombre y la batería, y al cambiar el control de ruido (desde
// el Centro de control o apretando el tallo) enseña el modo nuevo.
//
// Se va solo, como el volumen. Va por encima de él (70 contra 60) y por
// debajo de las notificaciones.
//
// Su ancho sigue al texto: el nombre de tus AirPods completo y lo de la
// derecha, entre el ancho mínimo de la isla y un tope (más allá, el nombre se
// corta con "…").

import QtQuick
import qs.core.theme
import qs.core.components.atoms
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
        if (root.charging)
            return Theme.systemIcons.airpods.batteryCharging;
        if (AirPods.lowest > 0.6)
            return Theme.systemIcons.airpods.batteryFull;
        if (AirPods.lowest > 0.2)
            return Theme.systemIcons.airpods.batteryMedium;
        return Theme.systemIcons.airpods.batteryLow;
    }

    readonly property string detailText: {
        if (root.showsMode)
            return AirPods.modes.find(m => m.id === AirPods.mode)?.short ?? "";
        if (root.hasBattery)
            return Math.round(AirPods.lowest * 100) + "%";
        return "Conectados";
    }

    // ── el ancho ──────────────────────────────────────────────────
    //
    // Se mide el texto con la misma fuente que la vista. Las medidas de
    // abajo son las que usa la vista: cambiar una aquí la cambia allá.
    readonly property int edge: 12          // aire a cada lado
    readonly property int glyph: 14         // los íconos
    readonly property int gap: 8            // ícono → texto
    readonly property int split: 16         // nombre → lo de la derecha
    readonly property int textSize: 12
    readonly property int maxWidth: 460

    TextMetrics {
        id: nameMetrics
        font.family: Theme.font.ui
        font.pixelSize: root.textSize
        font.weight: Font.DemiBold
        text: AirPods.name
    }

    TextMetrics {
        id: detailMetrics
        font.family: Theme.font.ui
        font.pixelSize: root.textSize
        text: root.detailText
    }

    contentWidth: {
        const detail = (root.detailIcon !== "" ? root.glyph + 6 : 0) + detailMetrics.advanceWidth;
        const inner = root.edge + root.glyph + root.gap + nameMetrics.advanceWidth
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
                icon: Theme.systemIcons.device.headphones
                size: root.glyph
                color: Theme.island.fg
            }

            Label {
                anchors.left: glyph.right
                anchors.leftMargin: root.gap
                anchors.right: detail.left
                anchors.rightMargin: root.split
                anchors.verticalCenter: parent.verticalCenter

                text: AirPods.name
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
                    color: root.lowBattery ? Theme.colors.error : Theme.island.fg
                }

                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: root.detailText
                    color: root.showsMode || root.hasBattery ? Theme.island.fg : Theme.island.muted
                    font.pixelSize: root.textSize
                }
            }
        }
    }
}
