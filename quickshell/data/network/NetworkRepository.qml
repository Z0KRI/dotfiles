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
                  || network.security === WifiSecurityType.Owe,
            security: root.securityName(network.security),
            enterprise: root.isEnterprise(network.security)
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

    // El nombre del tipo de seguridad, como lo dice macOS. Si tu versión de
    // Quickshell no conoce alguno de estos tipos, ese renglón vale
    // `undefined`, no coincide con nada y sale "" (nadie truena).
    function securityName(type) {
        const names = [
            [WifiSecurityType.Sae, "WPA3 Personal"],
            [WifiSecurityType.Wpa3SuiteB192, "WPA3 Empresarial"],
            [WifiSecurityType.Wpa2Psk, "WPA2 Personal"],
            [WifiSecurityType.Wpa2Eap, "WPA2 Empresarial"],
            [WifiSecurityType.WpaPsk, "WPA Personal"],
            [WifiSecurityType.WpaEap, "WPA Empresarial"],
            [WifiSecurityType.StaticWep, "WEP"],
            [WifiSecurityType.DynamicWep, "WEP"],
            [WifiSecurityType.Leap, "LEAP"]
        ];
        return names.find(entry => entry[0] !== undefined && entry[0] === type)?.[1] ?? "";
    }

    // Las redes de empresa piden usuario y certificados, no solo contraseña.
    function isEnterprise(type) {
        return [WifiSecurityType.Wpa3SuiteB192, WifiSecurityType.Wpa2Eap, WifiSecurityType.WpaEap,
                WifiSecurityType.DynamicWep, WifiSecurityType.Leap]
            .some(kind => kind !== undefined && kind === type);
    }

    function find(name) {
        return root.wifiDevice?.networks.values.find(n => n.name === name) ?? null;
    }
}