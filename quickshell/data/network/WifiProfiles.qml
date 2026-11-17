// REPOSITORIO: lo del Wi-Fi que Quickshell.Networking no sabe hacer, pedido a
// NetworkManager con su programa de consola, nmcli. Cuatro cosas:
//
//   1. LEER los perfiles guardados (las redes "conocidas") con sus ajustes:
//      conexión automática, MAC privada, IPv4/IPv6, DNS, proxy, MTU...
//   2. LEER el enlace: lo que la tarjeta Wi-Fi tiene AHORA (MAC, IP, máscara,
//      router, DNS). El perfil dice "usa DHCP"; el enlace dice qué le tocó.
//   3. ENTRAR a una red con contraseña (Networking solo entra a las que ya
//      tienen perfil o están abiertas).
//   4. CAMBIAR u OLVIDAR un perfil.
//
// Entrega datos planos y no decide nada: las reglas (qué es válido, qué
// cambió) son de domain/network/WifiControl. Aquí sí vive la TRADUCCIÓN:
// qué propiedad de NetworkManager corresponde a cada ajuste. Nadie más
// necesita saber que "Fija" se escribe `cloned-mac-address stable`.
//
// La lista de redes al alcance sigue saliendo de NetworkRepository; como los
// dos hablan con el mismo NetworkManager, lo que cambias aquí aparece allá.
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

    // nombre de red → el perfil (ver blankProfile() para los campos).
    property var profiles: ({})

    // Lo que tiene la tarjeta Wi-Fi ahora mismo (ver blankLink()).
    property var link: root.blankLink()

    // Lo mismo, pero de TODAS las tarjetas (Wi-Fi, Ethernet...): la lectura
    // es una sola, `nmcli device show`. Las de cable las usa WiredRepository.
    property var devices: []

    // El enlace "vacío": lo que se enseña de una red que no es la que está
    // en uso.
    readonly property var noLink: root.blankLink()

    // El perfil completo de la red cuyos detalles están abiertos, o null si
    // no hay ninguna (o todavía no llega). Se pide con readSettings(nombre).
    property string settingsFor: ""
    readonly property var settings: root.settingsFor !== "" ? (root.profiles[root.settingsFor] ?? null) : null

    function readSettings(name): void {
        root.settingsFor = name;
    }

    // { name, workgroup, wins }: el nombre del equipo y, si hay Samba, su
    // grupo de trabajo y servidor WINS. Es lo que enseña la pestaña WINS.
    property var host: ({ name: "", workgroup: "", wins: "" })

    signal joined(string name)
    // reason: "password", "gone", "timeout" u "other" (con el texto de nmcli).
    signal joinFailed(string name, string reason, string detail)

    readonly property bool joining: joiner.running

    function blankProfile(uuid) {
        return {
            uuid: uuid,
            // name: el nombre de la red Wi-Fi (SSID). id: el nombre del
            // perfil en NetworkManager. interfaceName: la tarjeta a la que
            // está amarrado ("" = cualquiera). Los dos últimos importan en
            // Ethernet, donde no hay SSID.
            name: "", id: "", interfaceName: "",
            autoconnect: true,
            metered: false,
            // "off" (la MAC real), "fixed" (una inventada, siempre la misma
            // en esa red) o "rotating" (una nueva cada vez).
            privateAddress: "off",
            // Direcciones IPv6 temporales: lo más cercano en Linux a
            // "Limitar seguimiento de dirección IP".
            ip6Privacy: false,
            ipv4Method: "auto", ipv4Address: "", ipv4Prefix: 24, ipv4Router: "",
            dhcpClientId: "",
            ipv6Method: "auto",
            // Los que escribiste tú. Vacío = los que reparta la red.
            dns: [], searchDomains: [],
            proxyAuto: false, pacUrl: "",
            mtu: 0,   // 0 = automática
            eap: "", identity: ""
        };
    }

    function blankLink() {
        return {
            device: "", type: "", product: "",
            // "connected", "connecting", "disconnected" (lista pero sin
            // usar) o "unavailable" (sin cable, o apagada).
            state: "unavailable",
            // El perfil que está usando ahora ("" si ninguno).
            connection: "", uuid: "",
            mac: "", mtu: 0, ip: "", prefix: 0, router: "", dns: [],
            domains: [], ip6: "", router6: ""
        };
    }

    // ── leer ─────────────────────────────────────────────────────
    function refresh(): void {
        if (profileReader.running)
            profileReader.rerun = true;
        else
            profileReader.running = true;

        if (!linkReader.running)
            linkReader.running = true;

        // El nombre del equipo no cambia: con una vez basta.
        if (root.host.name === "" && !hostReader.running)
            hostReader.running = true;
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
    // changes lleva SOLO lo que cambió, con los mismos nombres del perfil:
    //   autoconnect, metered, privateAddress, ip6Privacy, ipv6Method,
    //   dns, searchDomains, mtu, dhcpClientId,
    //   ipv4:  { method, address, prefix, router }   (los cuatro juntos)
    //   proxy: { auto, pacUrl }                      (los dos juntos)
    //
    // reconnect: después de guardar, volver a levantar la conexión para que
    // lo de red (IP, DNS, proxy, MTU) se use ya. Lo decide el dominio.
    function update(name: string, changes: var, reconnect: bool): void {
        const profile = root.profiles[name];
        if (!profile)
            return;

        const args = root.argsFor(changes);
        if (args.length === 0)
            return;

        // Optimista: quien mire el perfil ve el cambio sin esperar a nmcli.
        const merged = Object.assign({}, profile, changes);
        if (changes.ipv4) {
            merged.ipv4Method = changes.ipv4.method;
            merged.ipv4Address = changes.ipv4.address;
            merged.ipv4Prefix = changes.ipv4.prefix;
            merged.ipv4Router = changes.ipv4.router;
        }
        if (changes.proxy) {
            merged.proxyAuto = changes.proxy.auto;
            merged.pacUrl = changes.proxy.pacUrl;
        }
        const next = Object.assign({}, root.profiles);
        next[name] = merged;
        root.profiles = next;

        root.run(["nmcli", "connection", "modify", "uuid", profile.uuid].concat(args));

        if (reconnect)
            root.run(["nmcli", "connection", "up", "uuid", profile.uuid]);
    }

    // Vuelve a levantar la conexión de esa red: pide una concesión DHCP nueva.
    function reactivate(name): void {
        const profile = root.profiles[name];
        if (profile)
            root.run(["nmcli", "connection", "up", "uuid", profile.uuid]);
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

    // ── la traducción a NetworkManager ───────────────────────────
    readonly property var macModes: ({ off: "permanent", fixed: "stable", rotating: "random" })

    // kind: la sección del perfil donde vive la MTU, que cambia con el tipo
    // de conexión: "802-11-wireless" (Wi-Fi) u "802-3-ethernet" (cable).
    function argsFor(changes, kind = "802-11-wireless") {
        const args = [];

        if (changes.autoconnect !== undefined)
            args.push("connection.autoconnect", changes.autoconnect ? "yes" : "no");
        if (changes.metered !== undefined)
            args.push("connection.metered", changes.metered ? "yes" : "unknown");
        if (changes.privateAddress !== undefined)
            args.push("802-11-wireless.cloned-mac-address", root.macModes[changes.privateAddress] ?? "permanent");
        // 2 = usar direcciones temporales y preferirlas; 0 = no usarlas.
        if (changes.ip6Privacy !== undefined)
            args.push("ipv6.ip6-privacy", changes.ip6Privacy ? "2" : "0");

        // El orden importa: "manual" sin dirección no es válido, así que la
        // dirección va antes; y al volver a DHCP, primero el método.
        if (changes.ipv4 !== undefined) {
            if (changes.ipv4.method === "manual")
                args.push("ipv4.addresses", changes.ipv4.address + "/" + changes.ipv4.prefix,
                          "ipv4.gateway", changes.ipv4.router,
                          "ipv4.method", "manual");
            else
                args.push("ipv4.method", "auto", "ipv4.addresses", "", "ipv4.gateway", "");
        }

        if (changes.dhcpClientId !== undefined)
            args.push("ipv4.dhcp-client-id", changes.dhcpClientId);

        if (changes.ipv6Method !== undefined)
            args.push("ipv6.method", changes.ipv6Method);

        // Con servidores propios se ignoran los que reparte la red; sin
        // ellos, se vuelven a usar. Los IPv6 (llevan ":") van en su lado.
        if (changes.dns !== undefined) {
            const v4 = changes.dns.filter(server => server.indexOf(":") < 0);
            const v6 = changes.dns.filter(server => server.indexOf(":") >= 0);
            const own = changes.dns.length > 0 ? "yes" : "no";
            args.push("ipv4.dns", v4.join(","), "ipv4.ignore-auto-dns", own,
                      "ipv6.dns", v6.join(","), "ipv6.ignore-auto-dns", own);
        }

        if (changes.searchDomains !== undefined)
            args.push("ipv4.dns-search", changes.searchDomains.join(","));

        // NetworkManager solo sabe de proxy automático: descubrirlo solo
        // (WPAD) o con la dirección de un archivo PAC.
        if (changes.proxy !== undefined)
            args.push("proxy.method", changes.proxy.auto || changes.proxy.pacUrl !== "" ? "auto" : "none",
                      "proxy.pac-url", changes.proxy.pacUrl);

        if (changes.mtu !== undefined)
            args.push(kind + ".mtu", String(changes.mtu));   // 0 = automática

        return args;
    }

    // ── internos ─────────────────────────────────────────────────
    //
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

    // "a,b , c" → ["a", "b", "c"]; "" o "--" → [].
    function listOf(value) {
        if (value === "" || value === "--")
            return [];
        return value.split(/[,\s]+/).filter(part => part !== "");
    }

    // Los perfiles que vienen en el texto de nmcli, en orden. Cada uno
    // empieza con la línea `uuid:...` que pone el lector.
    function parseBlocks(text) {
        const found = [];
        let current = null;

        for (const line of text.split("\n")) {
            if (line === "")
                continue;

            const [key, raw] = root.split(line);
            const value = raw === "--" ? "" : raw;

            if (key === "uuid") {
                current = root.blankProfile(value);
                found.push(current);
            } else if (current) {
                root.readField(current, key, value);
            }
        }

        return found;
    }

    // Una línea `clave:valor` de un perfil, puesta en su campo.
    function readField(current, key, value): void {
        if (key === "802-11-wireless.ssid") {
            current.name = value;
        } else if (key === "connection.id") {
            current.id = value;
        } else if (key === "connection.interface-name") {
            current.interfaceName = value;
        } else if (key === "connection.autoconnect") {
            current.autoconnect = value === "yes";
        } else if (key === "connection.metered") {
            current.metered = value === "yes";
        } else if (key === "802-11-wireless.cloned-mac-address") {
            current.privateAddress = value === "stable" ? "fixed"
                                   : (value === "random" ? "rotating" : "off");
        } else if (key === "802-11-wireless.mtu" || key === "802-3-ethernet.mtu") {
            current.mtu = parseInt(value) || 0;   // "auto" → 0
        } else if (key === "ipv6.ip6-privacy") {
            current.ip6Privacy = parseInt(value) > 0;   // "2 (enabled, ...)"
        } else if (key === "ipv4.method") {
            current.ipv4Method = value;
        } else if (key === "ipv4.addresses") {
            const address = /^([\d.]+)\/(\d+)/.exec(value);
            if (address) {
                current.ipv4Address = address[1];
                current.ipv4Prefix = parseInt(address[2]);
            }
        } else if (key === "ipv4.gateway") {
            current.ipv4Router = value;
        } else if (key === "ipv4.dhcp-client-id") {
            current.dhcpClientId = value;
        } else if (key === "ipv4.dns" || key === "ipv6.dns") {
            current.dns = current.dns.concat(root.listOf(value));
        } else if (key === "ipv4.dns-search") {
            current.searchDomains = root.listOf(value);
        } else if (key === "ipv6.method") {
            current.ipv6Method = value;
        } else if (key === "proxy.method") {
            current.proxyAuto = value === "auto";
        } else if (key === "proxy.pac-url") {
            current.pacUrl = value;
        } else if (key === "802-1x.eap") {
            current.eap = value;
        } else if (key === "802-1x.identity") {
            current.identity = value;
        }
    }

    // Los de Wi-Fi, por nombre de red. Si dos perfiles son de la misma red,
    // se queda el primero.
    function parseProfiles(text) {
        const found = {};
        for (const profile of root.parseBlocks(text)) {
            if (profile.name !== "" && found[profile.name] === undefined)
                found[profile.name] = profile;
        }
        return found;
    }

    // `nmcli device show` contesta un bloque por tarjeta.
    function parseDevices(text) {
        const found = [];
        let current = null;

        for (const line of text.split("\n")) {
            const [key, raw] = root.split(line);
            const value = raw === "--" ? "" : raw;

            if (key === "GENERAL.DEVICE") {
                current = root.blankLink();
                current.device = value;
                found.push(current);
            } else if (!current) {
                continue;
            } else if (key === "GENERAL.TYPE") {
                current.type = value;
            } else if (key === "GENERAL.PRODUCT") {
                current.product = value;
            } else if (key === "GENERAL.STATE") {
                // "100 (connected)": el número es lo estable entre idiomas.
                const code = parseInt(value) || 0;
                current.state = code === 100 ? "connected"
                              : (code >= 40 && code < 100 ? "connecting"
                              : (code === 30 ? "disconnected" : "unavailable"));
            } else if (key === "GENERAL.CONNECTION") {
                current.connection = value;
            } else if (key === "GENERAL.CON-UUID") {
                current.uuid = value;
            } else if (key === "GENERAL.HWADDR") {
                current.mac = value.toLowerCase();
            } else if (key === "GENERAL.MTU") {
                current.mtu = parseInt(value) || 0;
            } else if (key.indexOf("IP4.ADDRESS") === 0 && current.ip === "") {
                const address = /^([\d.]+)\/(\d+)/.exec(value);
                if (address) {
                    current.ip = address[1];
                    current.prefix = parseInt(address[2]);
                }
            } else if (key === "IP4.GATEWAY") {
                current.router = value;
            } else if (key.indexOf("IP4.DNS") === 0) {
                current.dns.push(value);
            } else if (key.indexOf("IP4.DOMAIN") === 0) {
                current.domains.push(value);
            } else if (key.indexOf("IP6.ADDRESS") === 0) {
                // La primera que no sea de enlace local (fe80::), si hay.
                const address = value.replace(/\/\d+$/, "");
                if (current.ip6 === "" || (current.ip6.indexOf("fe80") === 0 && address.indexOf("fe80") !== 0))
                    current.ip6 = address;
            } else if (key === "IP6.GATEWAY") {
                current.router6 = value;
            }
        }

        return found;
    }

    function parseHost(text) {
        const host = { name: "", workgroup: "", wins: "" };
        for (const line of text.split("\n")) {
            const [key, value] = root.split(line);
            if (key === "host")
                host.name = value.trim();
            else if (key.toLowerCase() === "workgroup")
                host.workgroup = value.trim();
            else if (key.toLowerCase() === "wins server")
                host.wins = value.trim();
        }
        return host;
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

        // Un bloque por perfil de Wi-Fi: su uuid y sus secciones enteras.
        // La de 802-1x (redes de empresa) se pide aparte y callando errores:
        // casi ningún perfil la tiene, y no debe tirar lo demás. La sección
        // de seguridad, donde va la contraseña, NO se pide.
        command: ["sh", "-c",
            "nmcli -t -f UUID,TYPE connection show | while IFS=: read -r uuid type; do "
            + "[ \"$type\" = 802-11-wireless ] || continue; "
            + "echo \"uuid:$uuid\"; "
            + "nmcli -t -f connection,802-11-wireless,ipv4,ipv6,proxy connection show uuid \"$uuid\"; "
            + "nmcli -t -f 802-1x connection show uuid \"$uuid\" 2>/dev/null; "
            + "done; true"]

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

        // Secciones enteras y no campo por campo: un nombre de campo que
        // tu versión de nmcli no conozca tiraría toda la lectura.
        command: ["nmcli", "-t", "-f", "GENERAL,IP4,IP6", "device", "show"]

        stdout: StdioCollector {
            onStreamFinished: {
                root.devices = root.parseDevices(this.text);
                root.link = root.devices.find(device => device.type === "wifi") ?? root.blankLink();
            }
        }
    }

    Process {
        id: hostReader

        // El nombre del equipo y, si existe smb.conf, las dos líneas de Samba
        // que equivalen a la pestaña WINS, ya como `clave:valor`.
        command: ["sh", "-c",
            "printf 'host:%s\\n' \"$(cat /etc/hostname 2>/dev/null)\"; "
            + "sed -n 's/^[[:space:]]*\\(workgroup\\|wins server\\)[[:space:]]*=[[:space:]]*/\\1:/Ip' "
            + "/etc/samba/smb.conf 2>/dev/null; true"]

        stdout: StdioCollector {
            onStreamFinished: root.host = root.parseHost(this.text)
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
