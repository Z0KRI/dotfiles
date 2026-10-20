// CASO DE USO: el Wi-Fi del equipo.
// Reglas:
//   - Una fila por nombre de red: si hay varios puntos de acceso, gana el más fuerte.
//   - Orden: la conectada primero, luego las conocidas, luego por señal.
//   - Las redes sin nombre (ocultas) no se muestran.
//   - Una red con contraseña que nunca has usado no se conecta desde aquí:
//     se avisa y se ofrece la configuración de red.
//   - Señal en 3 niveles: fuerte, media y débil.

pragma Singleton

import Quickshell
import qs.data.network
import qs.data.applications
import qs.domain.launcher

Singleton {
    id: root

    readonly property bool available: NetworkRepository.hasWifi
    readonly property bool powered: NetworkRepository.wifiEnabled
    readonly property bool wired: NetworkRepository.wiredConnected

    readonly property var networks: {
        // Una entrada por nombre.
        const best = {};
        for (const network of NetworkRepository.networks) {
            if (!network.name)
                continue;

            const previous = best[network.name];
            if (!previous
                || network.connected
                || (!previous.connected && network.strength > previous.strength))
                best[network.name] = network;
        }

        return Object.values(best)
            .map(network => Object.assign({}, network, {
                level: root.levelOf(network.strength),
                needsPassword: !network.open && !network.known,
                detail: root.detailOf(network)
            }))
            .sort((a, b) => (b.connected - a.connected)
                            || (b.known - a.known)
                            || (b.strength - a.strength));
    }

    readonly property var current: root.networks.find(n => n.connected) ?? null

    // Estado bajo el título del mosaico.
    readonly property string status: {
        if (!root.available)
            return root.wired ? "Ethernet" : "No disponible";
        if (!root.powered)
            return "Desactivado";
        if (root.current)
            return root.current.name;
        return root.wired ? "Ethernet" : "Sin conexión";
    }

    // Ícono del mosaico.
    readonly property string level: {
        if (!root.available || !root.powered)
            return "off";
        if (!root.current)
            return "none";
        return root.current.level;
    }

    // Red que pidió contraseña al intentar entrar ("" si ninguna).
    property string passwordNeededFor: ""

    readonly property var settingsApp: AppRepository.entryFor("nm-connection-editor")
    readonly property bool hasSettingsApp: root.settingsApp !== null

    function setPowered(on): void {
        NetworkRepository.setWifiEnabled(on);
    }

    function toggle(): void {
        root.setPowered(!root.powered);
    }

    function setScanning(on): void {
        NetworkRepository.setScanning(on);
        if (!on)
            root.passwordNeededFor = "";
    }

    function choose(name): void {
        const network = root.networks.find(n => n.name === name);
        if (!network || network.connected)
            return;

        if (network.needsPassword) {
            root.passwordNeededFor = name;
            return;
        }

        root.passwordNeededFor = "";
        NetworkRepository.connectTo(name);
    }

    function openSettings(): void {
        if (root.settingsApp)
            LaunchApp.execute(root.settingsApp);
    }

    function levelOf(strength) {
        if (strength >= 0.66)
            return "high";
        if (strength >= 0.33)
            return "medium";
        return "low";
    }

    function detailOf(network) {
        if (network.busy)
            return network.connected ? "Desconectando…" : "Conectando…";
        if (network.connected)
            return "Conectada";
        if (network.known)
            return "Conocida";
        return "";
    }
}