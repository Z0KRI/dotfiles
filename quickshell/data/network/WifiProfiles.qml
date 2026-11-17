// REPOSITORIO: lo del Wi-Fi que Quickshell.Networking no sabe hacer, pedido a
// NetworkManager con su programa de consola, nmcli. Cuatro cosas:
//
//   1. LEER los perfiles guardados (las redes "conocidas") con sus ajustes:
//      si se conectan solas, si son de datos reducidos y qué dirección MAC usan.
//   2. LEER el enlace: la dirección MAC, la IP, el router y los DNS del Wi-Fi.
//   3. ENTRAR a una red con contraseña (Networking solo entra a las que ya
//      tienen perfil o están abiertas).
//   4. CAMBIAR u OLVIDAR un perfil.
//
// Entrega datos planos y no decide nada: las reglas son de
// domain/network/WifiControl. La lista de redes al alcance sigue saliendo de
// NetworkRepository; como los dos hablan con el mismo NetworkManager, lo que
// cambias aquí aparece allá solo.
//
// nmcli en modo -t ("terse") contesta `clave:valor`, y escapa con `\` los
// dos puntos que van DENTRO del valor (una MAC llega como 0E\:76\:3E...).
// De eso se encarga split().

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // nombre de red → { uuid, autoconnect, metered, privateAddress }
    //   privateAddress: "off" (la MAC real), "fixed" (una inventada, siempre
    //   la misma en esa red) o "rotating" (una nueva cada vez).
    property var profiles: ({})

    // { mac, ip, router, dns: [] } de la tarjeta Wi-Fi. Vacío si no hay.
    property var link: ({ mac: "", ip: "", router: "", dns: [] })

    signal joined(string name)
    // reason: "password", "gone", "timeout" u "other" (con el texto de nmcli).
    signal joinFailed(string name, string reason, string detail)

    readonly property bool joining: joiner.running

    // ── leer ─────────────────────────────────────────────────────
    function refresh(): void {
        if (profileReader.running)
            profileReader.rerun = true;
        else
            profileReader.running = true;

        if (!linkReader.running)
            linkReader.running = true;
    }

    // Varias cosas cambian a la vez al conectar: se lee una sola vez, al final.
    function refreshSoon(): void {
        later.restart();
    }

    // ── entrar ───────────────────────────────────────────────────
    //
    // OJO: la contraseña viaja como argumento de nmcli, así que durante el
    // intento se ve en la lista de procesos de TU usuario (`ps`). En un
    // equipo personal no pasa nada; NetworkManager la guarda después en su
    // perfil, como siempre.
    function join(name, password): void {
        if (joiner.running)
            return;

        joiner.name = name;
        joiner.wasKnown = root.profiles[name] !== undefined;
        joiner.command = ["nmcli", "--wait", "30", "device", "wifi", "connect", name, "password", password];
        joiner.running = true;
    }

    // ── cambiar y olvidar ────────────────────────────────────────
    //
    // changes: { autoconnect: bool, metered: bool, privateAddress: "off"|"fixed"|"rotating" }
    // Solo se manda lo que venga. La MAC nueva se usa a partir de la
    // siguiente conexión a esa red.
    function update(name: string, changes: var): void {
        const profile = root.profiles[name];
        if (!profile)
            return;

        const args = [];
        if (changes.autoconnect !== undefined)
            args.push("connection.autoconnect", changes.autoconnect ? "yes" : "no");
        if (changes.metered !== undefined)
            args.push("connection.metered", changes.metered ? "yes" : "unknown");
        if (changes.privateAddress !== undefined)
            args.push("802-11-wireless.cloned-mac-address", root.macModes[changes.privateAddress] ?? "permanent");

        if (args.length === 0)
            return;

        // Optimista: la hoja de detalles ve el cambio sin esperar a nmcli.
        const next = Object.assign({}, root.profiles);
        next[name] = Object.assign({}, profile, changes);
        root.profiles = next;

        root.run(["nmcli", "connection", "modify", "uuid", profile.uuid].concat(args));
    }

    function forget(name): void {
        const profile = root.profiles[name];
        if (!profile)
            return;

        const next = Object.assign({}, root.profiles);
        delete next[name];
        root.profiles = next;

        root.run(["nmcli", "connection", "delete", "uuid", profile.uuid]);
    }

    // ── internos ─────────────────────────────────────────────────
    readonly property var macModes: ({ off: "permanent", fixed: "stable", rotating: "random" })

    // Las órdenes cortas van en fila: una termina y sale la siguiente.
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

    // "clave:valor" → [clave, valor], respetando los `\:` del valor.
    function split(line) {
        let cut = -1;
        for (let i = 0; i < line.length; i++) {
            if (line[i] === "\\") {
                i++;
                continue;
            }
            if (line[i] === ":") {
                cut = i;
                break;
            }
        }

        if (cut < 0)
            return [line, ""];
        return [line.slice(0, cut), line.slice(cut + 1).replace(/\\(.)/g, "$1")];
    }

    function parseProfiles(text) {
        const found = {};
        let current = null;

        const close = () => {
            // Si dos perfiles son de la misma red, se queda el primero.
            if (current && current.name !== "" && found[current.name] === undefined)
                found[current.name] = current;
        };

        for (const line of text.split("\n")) {
            if (line === "")
                continue;

            const [key, value] = root.split(line);
            if (key === "uuid") {
                close();
                current = { uuid: value, name: "", autoconnect: true, metered: false, privateAddress: "off" };
            } else if (!current) {
                continue;
            } else if (key === "802-11-wireless.ssid") {
                current.name = value;
            } else if (key === "connection.autoconnect") {
                current.autoconnect = value === "yes";
            } else if (key === "connection.metered") {
                current.metered = value === "yes";
            } else if (key === "802-11-wireless.cloned-mac-address") {
                current.privateAddress = value === "stable" ? "fixed"
                                       : (value === "random" ? "rotating" : "off");
            }
        }

        close();
        return found;
    }

    // `nmcli device show` contesta un bloque por tarjeta; interesa el de Wi-Fi.
    function parseLink(text) {
        const empty = { mac: "", ip: "", router: "", dns: [] };
        let current = null;
        let wifi = null;

        for (const line of text.split("\n")) {
            const [key, value] = root.split(line);
            if (key === "GENERAL.DEVICE") {
                current = { mac: "", ip: "", router: "", dns: [] };
            } else if (!current) {
                continue;
            } else if (key === "GENERAL.TYPE") {
                if (value === "wifi" && !wifi)
                    wifi = current;
            } else if (key === "GENERAL.HWADDR") {
                current.mac = value.toLowerCase();
            } else if (key.indexOf("IP4.ADDRESS") === 0 && current.ip === "") {
                current.ip = value.replace(/\/\d+$/, "");
            } else if (key === "IP4.GATEWAY") {
                current.router = value === "--" ? "" : value;
            } else if (key.indexOf("IP4.DNS") === 0) {
                current.dns.push(value);
            }
        }

        return wifi ?? empty;
    }

    // Por qué falló nmcli, en una palabra.
    function reasonOf(text) {
        if (/Secrets were required|psk|password|802-1x|invalid/i.test(text))
            return "password";
        if (/No network with SSID|not found/i.test(text))
            return "gone";
        if (/Timeout|timed out/i.test(text))
            return "timeout";
        return "other";
    }

    Process {
        id: profileReader

        property bool rerun: false

        // Un bloque por perfil de Wi-Fi: su uuid y los cuatro ajustes.
        command: ["sh", "-c",
            "nmcli -t -f UUID,TYPE connection show | while IFS=: read -r uuid type; do "
            + "[ \"$type\" = 802-11-wireless ] || continue; "
            + "echo \"uuid:$uuid\"; "
            + "nmcli -t -f 802-11-wireless.ssid,connection.autoconnect,connection.metered,"
            + "802-11-wireless.cloned-mac-address connection show uuid \"$uuid\"; "
            + "done"]

        stdout: StdioCollector {
            onStreamFinished: root.profiles = root.parseProfiles(this.text)
        }

        onExited: (exitCode, exitStatus) => {
            if (profileReader.rerun) {
                profileReader.rerun = false;
                profileReader.running = true;
            }
        }
    }

    Process {
        id: linkReader

        command: ["nmcli", "-t", "-f",
                  "GENERAL.DEVICE,GENERAL.TYPE,GENERAL.HWADDR,IP4.ADDRESS,IP4.GATEWAY,IP4.DNS",
                  "device", "show"]

        stdout: StdioCollector {
            onStreamFinished: root.link = root.parseLink(this.text)
        }
    }

    Process {
        id: joiner

        property string name: ""
        property bool wasKnown: false
        property string output: ""

        // nmcli escribe "Error: ..." por la salida de errores.
        stdout: StdioCollector {
            onStreamFinished: joiner.output += this.text
        }
        stderr: StdioCollector {
            onStreamFinished: joiner.output += this.text
        }

        onStarted: joiner.output = ""

        onExited: (exitCode, exitStatus) => {
            const name = joiner.name;
            // Fuera del proceso cuanto antes: el comando lleva la contraseña.
            joiner.command = [];

            if (exitCode === 0) {
                root.joined(name);
            } else {
                // nmcli deja guardado el perfil aunque la contraseña esté mal;
                // si era nuevo se borra, o la red quedaría como "conocida".
                if (!joiner.wasKnown)
                    root.run(["nmcli", "connection", "delete", "id", name]);
                root.joinFailed(name, root.reasonOf(joiner.output), joiner.output.trim());
            }

            root.refreshSoon();
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
