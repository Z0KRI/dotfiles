// REPOSITORIO: único archivo que conoce BlueZ (vía Quickshell.Bluetooth).
// Entrega datos planos, nunca objetos de Bluetooth.

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Bluetooth

Singleton {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    readonly property bool available: root.adapter !== null
    readonly property bool powered: root.adapter?.enabled ?? false
    readonly property bool discovering: root.adapter?.discovering ?? false

    // Cómo te ven los demás dispositivos (el nombre del adaptador).
    readonly property string adapterName: root.adapter?.name ?? ""

    // Dispositivos emparejados: los que ya conoces, como en macOS.
    readonly property var devices: root.adapter
        ? root.adapter.devices.values
            .filter(device => device.paired || device.bonded)
            .map(device => root.plain(device))
        : []

    // Cercanos: los que aparecen al buscar y todavía no emparejas. Los que no
    // anuncian nombre (solo su dirección) no se listan: no sabrías cuál es.
    readonly property var nearby: root.adapter
        ? root.adapter.devices.values
            .filter(device => !device.paired && !device.bonded
                              && (device.name || device.deviceName))
            .map(device => root.plain(device))
        : []

    // El que acabas de pedir emparejar. Cuando termine, se conecta solo.
    property string pairingAddress: ""

    function plain(device) {
        return {
            address: device.address,
            name: device.name || device.deviceName || device.address,
            icon: device.icon,
            connected: device.connected,
            pairing: device.pairing,
            battery: device.batteryAvailable ? device.battery : -1
        };
    }

    function find(address) {
        return root.adapter?.devices.values.find(d => d.address === address) ?? null;
    }

    function setPowered(on): void {
        if (root.adapter)
            root.adapter.enabled = on;
    }

    function setDiscovering(on): void {
        if (root.adapter && root.adapter.discovering !== on)
            root.adapter.discovering = on;
    }

    function setConnected(address, on): void {
        const device = root.find(address);
        if (!device)
            return;

        if (on)
            device.connect();
        else
            device.disconnect();
    }

    // Emparejar = pair() + marcarlo de confianza (para que se reconecte solo
    // la próxima vez) + conectar en cuanto quede emparejado.
    function pair(address): void {
        const device = root.find(address);
        if (!device)
            return;

        root.pairingAddress = address;
        device.trusted = true;
        device.pair();
    }

    function cancelPair(address): void {
        const device = root.find(address);
        if (device && device.pairing)
            device.cancelPair();

        if (root.pairingAddress === address)
            root.pairingAddress = "";
    }

    // Olvidar = desemparejar. BlueZ borra las llaves y deja de reconectarlo.
    function forget(address): void {
        const device = root.find(address);
        if (device)
            device.forget();
    }

    // Un Connections por dispositivo, igual que en HyprlandRepository: así nos
    // enteramos de cuándo termina de emparejarse el que pediste.
    Variants {
        model: root.adapter ? root.adapter.devices.values : []

        Connections {
            id: watcher

            required property var modelData
            target: watcher.modelData

            function onPairedChanged() {
                const device = watcher.modelData;

                if (device.paired && device.address === root.pairingAddress) {
                    root.pairingAddress = "";
                    device.connect();
                }
            }
        }
    }
}
