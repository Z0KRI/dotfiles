// REPOSITORIO: único archivo que conoce NetworkManager (vía Quickshell.Networking).
// Entrega datos planos (textos, números, objetos simples), nunca objetos de red.

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Networking

Singleton {
    id: root

    readonly property var wifiDevice: Networking.devices.values
        .find(device => device.type === DeviceType.Wifi) ?? null

    readonly property bool hasWifi: root.wifiDevice !== null

    readonly property bool wiredConnected: Networking.devices.values
        .some(device => device.type === DeviceType.Wired && device.connected)

    readonly property bool wifiEnabled: Networking.wifiEnabled

    readonly property var networks: root.wifiDevice
        ? root.wifiDevice.networks.values.map(network => ({
            name: network.name,
            strength: network.signalStrength,
            connected: network.connected,
            known: network.known,
            busy: network.stateChanging,
            open: network.security === WifiSecurityType.Open
                  || network.security === WifiSecurityType.Owe
        }))
        : []

    function setWifiEnabled(on): void {
        Networking.wifiEnabled = on;
    }

    // Mientras está encendido, NetworkManager mantiene la lista al día.
    function setScanning(on): void {
        if (root.wifiDevice)
            root.wifiDevice.scannerEnabled = on;
    }

    function connectTo(name): void {
        const network = root.find(name);
        if (network)
            network.connect();
    }

    function disconnectFrom(name): void {
        const network = root.find(name);
        if (network)
            network.disconnect();
    }

    function find(name) {
        return root.wifiDevice?.networks.values.find(n => n.name === name) ?? null;
    }
}