// CASO DE USO: el servicio de BlueFerry (el puente con tu iPhone).
// Reglas:
//   - "Activo" = el servicio de BlueFerry corre.
//   - Estado: el nombre del iPhone si está conectado; si el servicio
//     corre pero el iPhone no está, "Esperando al iPhone".
//   - Sin Bluetooth no hay puente: el estado lo dice.
//   - Aviso de llegada (`arrived`), para la isla: cuando el iPhone termina
//     de conectarse. No al arrancar la shell si ya estaba, ni cuando vuelve
//     tras un parpadeo de unos segundos.
//
// Antes vivía en domain/bluetooth con el nombre PhoneBridge. Ese nombre ahora
// es del puente de mensajes (data/phone/PhoneBridge.qml) y dos tipos con el
// mismo nombre se pisan en cuanto un archivo importa las dos carpetas. Por eso
// este se llama PhoneService y vive junto a Phone, que es su pareja: Phone
// responde mensajes, PhoneService enciende y apaga el puente.

pragma Singleton

import QtQuick
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

    // ── aviso de llegada ──────────────────────────────────────────
    //
    // Se mira BlueZ y no a BlueFerry por dos razones. Es la misma fuente que
    // el Centro de control: si la isla dice "conectado", el Centro de control
    // dice lo mismo. Y no cuesta nada: Quickshell ya escucha a BlueZ, y
    // preguntarle a BlueFerry obligaría a tener vivo su puente de Python.
    //
    // El orden al conectarse: primero el Bluetooth clásico (mensajes y
    // contactos) y, unos segundos después, Bluetooth LE (las notificaciones y
    // la batería). "Conectado del todo" es cuando llega lo segundo, y eso se
    // ve en BlueZ: la batería aparece cuando LE ya está arriba. Así que al
    // llegar sin batería se espera a que llegue, hasta `settle`; si no llega
    // (un iPhone que no la reporta), se avisa igual al acabarse la espera.

    signal arrived(var phone)

    readonly property int settle: 8000

    // Menos que esto fuera no cuenta como irse: el iPhone a veces suelta la
    // conexión y la retoma al momento, y cada parpadeo sería un aviso.
    readonly property int blip: 20000

    // La dirección del iPhone conectado, o "". Se compara por dirección y no
    // por objeto: `phone` es una copia nueva cada vez que cambia cualquier
    // cosa de cualquier aparato (la batería de los AirPods, por ejemplo), y
    // eso no es que el iPhone haya llegado.
    property string _present: ""

    // Cuándo se fue, en milisegundos. 0 = no se ha ido desde que arrancó la
    // shell, y entonces al llegar siempre se avisa (el caso de encender la
    // computadora).
    property real _leftAt: 0

    // Al arrancar la shell, Bluetooth publica su estado de golpe: lo que ya
    // estaba conectado no es ninguna novedad.
    property bool _armed: false

    // Llegó, pero todavía sin Bluetooth LE: el aviso espera.
    property bool _waiting: false

    Timer {
        interval: 3000
        running: true
        onTriggered: {
            root._present = root.phone ? root.phone.address : "";
            root._armed = true;
        }
    }

    // Se acabó la espera sin batería: se avisa con lo que hay.
    Timer {
        id: settling
        interval: root.settle
        onTriggered: root._announce()
    }

    onPhoneChanged: {
        if (!root._armed)
            return;

        const address = root.phone ? root.phone.address : "";

        if (address === root._present) {
            // El que esperábamos terminó de conectarse.
            if (root._waiting && root.phone.battery >= 0)
                root._announce();

            // Si no, cambió otra cosa (la batería, otro aparato), no el
            // iPhone.
            return;
        }

        const before = root._present;
        root._present = address;

        // Se fue. Si estaba a medio conectarse, no se avisa nada: una
        // conexión que se cae al momento no es una llegada. Y tampoco cuenta
        // como irse: nunca estuvo del todo, así que al volver no es un
        // parpadeo de algo que ya conocías.
        if (address === "") {
            if (!root._waiting)
                root._leftAt = Date.now();
            root._waiting = false;
            settling.stop();
            return;
        }

        // Volvió tras un parpadeo: no se avisa. Un teléfono que reemplaza
        // a otro sin pasar por "ninguno" (`before` no vacío) sí se avisa.
        const away = root._leftAt === 0 ? Infinity : Date.now() - root._leftAt;
        if (before === "" && away < root.blip)
            return;

        if (root.phone.battery >= 0) {
            root._announce();
            return;
        }

        root._waiting = true;
        settling.restart();
    }

    function _announce(): void {
        settling.stop();
        root._waiting = false;

        if (root.phone)
            root.arrived(root.phone);
    }
}
