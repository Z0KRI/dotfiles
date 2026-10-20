// CASO DE USO: el puente con tu iPhone (BlueFerry), en lugar de AirDrop.
// Reglas:
//   - "Activo" = el servicio de BlueFerry corre.
//   - Estado: el nombre del iPhone si está conectado; si el servicio
//     corre pero el iPhone no está, "Esperando al iPhone".
//   - Sin Bluetooth no hay puente: el estado lo dice.

pragma Singleton

import Quickshell
import qs.data.bluetooth

Singleton {
    id: root

    readonly property bool active: BlueFerryRepository.running

    readonly property var phone: BluetoothControl.devices
        .find(device => device.kind === "phone" && device.connected) ?? null

    readonly property string status: {
        if (!root.active)
            return "Desactivado";
        if (!BluetoothControl.powered)
            return "Bluetooth apagado";
        if (root.phone)
            return root.phone.name;
        return "Esperando al iPhone";
    }

    function toggle(): void {
        BlueFerryRepository.setRunning(!root.active);
    }

    function openApp(): void {
        BlueFerryRepository.openApp();
    }

    function watch(): void {
        BlueFerryRepository.watch();
    }

    function unwatch(): void {
        BlueFerryRepository.unwatch();
    }
}