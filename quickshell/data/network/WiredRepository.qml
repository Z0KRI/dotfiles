// REPOSITORIO: las conexiones por cable (Ethernet), pedidas a NetworkManager
// con nmcli. Es el hermano de WifiProfiles y se apoya en él para no repetir:
//
//   - Las TARJETAS (qué hay conectado, con qué IP) ya las lee WifiProfiles,
//     porque `nmcli device show` contesta todas de una vez. Aquí solo se
//     filtran las de cable.
//   - Leer una línea de nmcli (split), convertir un perfil (parseBlocks) y
//     traducir cambios a argumentos (argsFor) son las mismas funciones.
//
// Lo propio de aquí: leer los PERFILES de cable, y las órdenes de un
// servicio de red: guardar cambios, activar o desactivar la tarjeta, y
// eliminar el perfil.
//
// Entrega datos planos y no decide nada: qué perfil le toca a cada tarjeta
// y qué se enseña es de domain/network/EthernetControl.

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // Las tarjetas de cable (ver WifiProfiles.blankLink() para los campos).
    readonly property var devices: WifiProfiles.devices.filter(device => device.type === "ethernet")

    // Los perfiles de cable guardados, en el orden de NetworkManager
    // (ver WifiProfiles.blankProfile()).
    property var profiles: []
    property bool loaded: false

    // ── leer ─────────────────────────────────────────────────────
    function refresh(): void {
        // Las tarjetas (y el nombre del equipo) vienen de allá.
        WifiProfiles.refresh();

        if (reader.running)
            reader.rerun = true;
        else
            reader.running = true;
    }

    function refreshSoon(): void {
        later.restart();
    }

    function find(uuid) {
        return root.profiles.find(profile => profile.uuid === uuid) ?? null;
    }

    // ── cambiar ──────────────────────────────────────────────────
    //
    // changes: lo mismo que WifiProfiles.update(). reconnect: volver a
    // levantar la conexión para que lo de red se use ya.
    function update(uuid: string, changes: var, reconnect: bool): void {
        const profile = root.find(uuid);
        if (!profile)
            return;

        const args = WifiProfiles.argsFor(changes, "802-3-ethernet");
        if (args.length === 0)
            return;

        root.run(["nmcli", "connection", "modify", "uuid", uuid].concat(args));
        if (reconnect)
            root.run(["nmcli", "connection", "up", "uuid", uuid]);
    }

    // Vuelve a levantar la conexión: pide una concesión DHCP nueva.
    function reactivate(uuid): void {
        root.run(["nmcli", "connection", "up", "uuid", uuid]);
    }

    // Activar: NetworkManager elige el perfil que le toca a la tarjeta (o
    // crea uno). Desactivar: la suelta y ya no se reconecta sola hasta que
    // la actives o reinicies.
    function setActive(device, on): void {
        root.run(["nmcli", "device", on ? "connect" : "disconnect", device]);
    }

    function remove(uuid): void {
        root.profiles = root.profiles.filter(profile => profile.uuid !== uuid);
        root.run(["nmcli", "connection", "delete", "uuid", uuid]);
    }

    // ── internos ─────────────────────────────────────────────────
    //
    // Las órdenes van en fila: una termina y sale la siguiente.
    property var queue: []

    function run(command): void {
        root.queue = root.queue.concat([command]);
        root.next();
    }

    function next(): void {
        if (runner.running || root.queue.length === 0)
            return;

        runner.command = root.queue[0];
        root.queue = root.queue.slice(1);
        runner.running = true;
    }

    Process {
        id: reader

        property bool rerun: false

        // Un bloque por perfil de cable: su uuid y sus secciones enteras.
        command: ["sh", "-c",
            "nmcli -t -f UUID,TYPE connection show | while IFS=: read -r uuid type; do "
            + "[ \"$type\" = 802-3-ethernet ] || continue; "
            + "echo \"uuid:$uuid\"; "
            + "nmcli -t -f connection,802-3-ethernet,ipv4,ipv6,proxy connection show uuid \"$uuid\"; "
            + "nmcli -t -f 802-1x connection show uuid \"$uuid\" 2>/dev/null; "
            + "done; true"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.profiles = WifiProfiles.parseBlocks(this.text);
                root.loaded = true;
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (reader.rerun) {
                reader.rerun = false;
                reader.running = true;
            }
        }
    }

    Process {
        id: runner

        onExited: (exitCode, exitStatus) => {
            root.refreshSoon();
            root.next();
        }
    }

    Timer {
        id: later
        interval: 500
        onTriggered: root.refresh()
    }
}
