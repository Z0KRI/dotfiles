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
//   - Batería: la que anuncia por Bluetooth y, si no, la que sabe UPower
//     (los teclados y mouses la reportan por HID, no por BlueZ).
//   - Emparejar va por BluetoothPairing, que enseña el código si lo piden.
//   - Estado del mosaico: Desactivado / Activado / nombre / "N dispositivos".

pragma Singleton

import Quickshell
import qs.data.bluetooth
import qs.data.power
import qs.data.applications
import qs.domain.launcher

Singleton {
    id: root

    readonly property bool available: BluetoothRepository.available
    readonly property bool powered: BluetoothRepository.powered
    readonly property bool discovering: BluetoothRepository.discovering
    readonly property string adapterName: BluetoothRepository.adapterName

    readonly property var devices: BluetoothRepository.devices
        .map(device => {
            const battery = root.batteryOf(device);
            return Object.assign({}, device, {
                kind: root.kindOf(device.icon),
                battery: battery.level,
                charging: battery.charging,
                detail: root.detailOf(device, battery)
            });
        })
        .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name));

    readonly property var nearby: BluetoothRepository.nearby
        .map(device => Object.assign({}, device, {
            kind: root.kindOf(device.icon),
            pairing: BluetoothPairing.isPairing(device.address),
            detail: BluetoothPairing.isPairing(device.address) ? "Emparejando…" : ""
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
        const device = root.nearby.find(d => d.address === address);
        BluetoothPairing.start(address, device?.name ?? address, device?.kind ?? "bluetooth");
    }

    function cancelPair(address): void {
        if (BluetoothPairing.isPairing(address))
            BluetoothPairing.cancel();
    }

    function forget(address): void {
        BluetoothRepository.forget(address);
    }

    function openSettings(): void {
        if (root.settingsApp)
            LaunchApp.execute(root.settingsApp);
    }

    // { level: 0..1 o -1, charging }
    function batteryOf(device) {
        if (device.battery >= 0)
            return { level: device.battery, charging: false };

        const power = device.connected ? UPowerRepository.forAddress(device.address) : null;
        if (power)
            return { level: power.percent, charging: power.charging };

        return { level: -1, charging: false };
    }

    function detailOf(device, battery) {
        if (!device.connected)
            return "";
        if (battery.level >= 0)
            return "Conectado · " + Math.round(battery.level * 100) + "%" + (battery.charging ? " · cargando" : "");
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
