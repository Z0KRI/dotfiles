pragma Singleton

// REPOSITORIO: la batería de los periféricos (teclado, mouse, control), vía
// UPower. Es el único archivo que conoce Quickshell.Services.UPower.
//
// ¿Por qué no la saca BlueZ? BlueZ solo sabe la batería de lo que la
// anuncia por Bluetooth (audífonos, algunos mouses). Un teclado Apple la
// reporta por HID, el mismo canal de las teclas; el kernel la convierte en
// /sys/class/power_supply/hid-<MAC>-battery y UPower la publica. Por eso el
// `nativePath` de esos dispositivos lleva la MAC adentro: así se emparejan con
// la lista de Bluetooth.
//
// Las baterías de una laptop se dejan fuera: esto es solo lo que se conecta.

import QtQuick
import Quickshell
import Quickshell.Services.UPower

Singleton {
    id: root

    readonly property var peripherals: UPower.devices.values
        .filter(device => device.ready && !device.isLaptopBattery && !device.powerSupply)
        .map(device => ({
            path: device.nativePath,
            model: device.model,
            percent: device.percentage,     // de 0 a 1
            charging: device.state === UPowerDeviceState.Charging
                      || device.state === UPowerDeviceState.PendingCharge
        }));

    // La batería del dispositivo con esta MAC, o null si UPower no la sabe.
    function forAddress(address) {
        const mac = String(address || "").toLowerCase();
        if (mac === "")
            return null;
        return root.peripherals.find(device => String(device.path).toLowerCase().indexOf(mac) >= 0) ?? null;
    }
}
