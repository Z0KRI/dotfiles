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

    // Dispositivos emparejados: los que ya conoces, como en macOS.
    readonly property var devices: root.adapter
        ? root.adapter.devices.values
            .filter(device => device.paired || device.bonded)
            .map(device => ({
                address: device.address,
                name: device.name || device.deviceName || device.address,
                icon: device.icon,
                connected: device.connected,
                battery: device.batteryAvailable ? device.battery : -1
            }))
        : []

    function setPowered(on): void {
        if (root.adapter)
            root.adapter.enabled = on;
    }

    function setConnected(address, on): void {
        const device = root.adapter?.devices.values.find(d => d.address === address);
        if (!device)
            return;

        if (on)
            device.connect();
        else
            device.disconnect();
    }
}