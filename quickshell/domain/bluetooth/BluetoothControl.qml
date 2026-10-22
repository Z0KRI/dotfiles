// CASO DE USO: el Bluetooth del equipo.
// Reglas:
//   - "Mis dispositivos" son los emparejados; los "cercanos" aparecen solo
//     mientras alguien busca (la página de Bluetooth de Ajustes).
//   - Buscar gasta batería y radio: se busca mientras haya alguien mirando
//     Y el Bluetooth esté encendido. Si lo enciendes con la página abierta,
//     la búsqueda arranca sola; si lo apagas, se para.
//   - Orden: conectados primero, luego por nombre.
//   - El tipo sale del ícono que reporta el sistema: audífonos, bocina,
//     teléfono, teclado, ratón, control, computadora; lo demás, genérico.
//   - Estado del mosaico: Desactivado / Activado / nombre / "N dispositivos".

pragma Singleton

import Quickshell
import qs.data.bluetooth
import qs.data.applications
import qs.domain.launcher

Singleton {
    id: root

    readonly property bool available: BluetoothRepository.available
    readonly property bool powered: BluetoothRepository.powered
    readonly property bool discovering: BluetoothRepository.discovering
    readonly property string adapterName: BluetoothRepository.adapterName

    readonly property var devices: BluetoothRepository.devices
        .map(device => Object.assign({}, device, {
            kind: root.kindOf(device.icon),
            detail: root.detailOf(device)
        }))
        .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name));

    readonly property var nearby: BluetoothRepository.nearby
        .map(device => Object.assign({}, device, {
            kind: root.kindOf(device.icon),
            detail: device.pairing ? "Emparejando…" : ""
        }))
        .sort((a, b) => a.name.localeCompare(b.name));

    readonly property var connected: root.devices.filter(d => d.connected)

    readonly property string status: {
        if (!root.available)
            return "No disponible";
        if (!root.powered)
            return "Desactivado";
        if (root.connected.length === 0)
            return "Activado";
        if (root.connected.length === 1)
            return root.connected[0].name;
        return root.connected.length + " dispositivos";
    }

    readonly property var settingsApp: AppRepository.entryFor("blueman-manager")
    readonly property bool hasSettingsApp: root.settingsApp !== null

    // Cuántos miran la lista de cercanos (la página de Bluetooth de Ajustes).
    property int discoveryWatchers: 0

    // No es una orden, es una consecuencia: "buscar" se DERIVA de quién mira
    // y de si hay Bluetooth. Así no hay que acordarse de reintentar al
    // encenderlo: cuando cambia `powered`, esto cambia solo.
    readonly property bool wantsDiscovery: root.discoveryWatchers > 0 && root.powered
    onWantsDiscoveryChanged: BluetoothRepository.setDiscovering(root.wantsDiscovery)

    function setPowered(on): void {
        BluetoothRepository.setPowered(on);
    }

    function toggle(): void {
        root.setPowered(!root.powered);
    }

    function toggleDevice(address): void {
        const device = root.devices.find(d => d.address === address);
        if (device)
            BluetoothRepository.setConnected(address, !device.connected);
    }

    function startDiscovery(): void {
        root.discoveryWatchers++;
    }

    function stopDiscovery(): void {
        root.discoveryWatchers = Math.max(0, root.discoveryWatchers - 1);
    }

    function pair(address): void {
        BluetoothRepository.pair(address);
    }

    function cancelPair(address): void {
        BluetoothRepository.cancelPair(address);
    }

    function forget(address): void {
        BluetoothRepository.forget(address);
    }

    function openSettings(): void {
        if (root.settingsApp)
            LaunchApp.execute(root.settingsApp);
    }

    function detailOf(device) {
        if (!device.connected)
            return "";
        if (device.battery >= 0)
            return "Conectado · " + Math.round(device.battery * 100) + "%";
        return "Conectado";
    }

    function kindOf(icon) {
        const name = icon ?? "";
        if (/headset|headphone/.test(name))
            return "headphones";
        if (/audio/.test(name))
            return "speaker";
        if (/phone/.test(name))
            return "phone";
        if (/keyboard/.test(name))
            return "keyboard";
        if (/mouse|tablet/.test(name))
            return "mouse";
        if (/gaming/.test(name))
            return "gamepad";
        if (/computer/.test(name))
            return "laptop";
        return "bluetooth";
    }
}
