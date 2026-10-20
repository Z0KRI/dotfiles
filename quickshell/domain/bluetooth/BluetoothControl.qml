// CASO DE USO: el Bluetooth del equipo.
// Reglas:
//   - Solo se listan dispositivos emparejados; los nuevos se emparejan
//     desde la configuración de Bluetooth.
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

    readonly property var devices: BluetoothRepository.devices
        .map(device => Object.assign({}, device, {
            kind: root.kindOf(device.icon),
            detail: root.detailOf(device)
        }))
        .sort((a, b) => (b.connected - a.connected) || a.name.localeCompare(b.name));

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