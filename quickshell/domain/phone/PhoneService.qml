// CASO DE USO: el servicio de BlueFerry (el puente con tu iPhone).
// Reglas:
//   - "Activo" = el servicio de BlueFerry corre.
//   - Estado: el nombre del iPhone si está conectado; si el servicio
//     corre pero el iPhone no está, "Esperando al iPhone".
//   - Sin Bluetooth no hay puente: el estado lo dice.
//
// Antes vivía en domain/bluetooth con el nombre PhoneBridge. Ese nombre ahora
// es del puente de mensajes (data/phone/PhoneBridge.qml) y dos tipos con el
// mismo nombre se pisan en cuanto un archivo importa las dos carpetas. Por eso
// este se llama PhoneService y vive junto a Phone, que es su pareja: Phone
// responde mensajes, PhoneService enciende y apaga el puente.

pragma Singleton

import Quickshell
import qs.data.bluetooth
import qs.domain.bluetooth

Singleton {
    id: root

    readonly property bool active: BlueFerryRepository.running

    readonly property var phone: BluetoothControl.devices
        .find(device => device.kind === "phone" && device.connected) ?? null

    // 0 a 1, o -1 si el teléfono no reporta su batería.
    readonly property real battery: root.phone ? root.phone.battery : -1

    readonly property string status: {
        if (!root.active)
            return "Desactivado";
        if (!BluetoothControl.powered)
            return "Bluetooth apagado";
        if (root.phone)
            return root.phone.name;
        return "Esperando al iPhone";
    }

    function setActive(on): void {
        BlueFerryRepository.setRunning(on);
    }

    function toggle(): void {
        root.setActive(!root.active);
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
