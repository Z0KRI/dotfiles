// CASO DE USO: el Wi-Fi del equipo.
// Reglas:
//   - Una fila por nombre de red: si hay varios puntos de acceso, gana el más fuerte.
//   - Orden: la conectada primero, luego las conocidas, luego por señal.
//   - Las redes sin nombre (ocultas) no se muestran.
//   - Dos listas: las CONOCIDAS (ya tienen perfil guardado, o es la actual) y
//     las OTRAS.
//   - Una red con contraseña que nunca has usado la pide (passwordNeededFor);
//     Ajustes enseña la hoja. Las de empresa (usuario + certificado) no se
//     pueden configurar desde aquí, y se dice.
//   - Si la contraseña está mal, la hoja sigue abierta con el motivo.
//   - Los detalles de una red se editan en borrador y se guardan con Aceptar;
//     solo se manda a NetworkManager lo que cambió.
//   - Olvidar una red siempre pasa por una confirmación.
//   - Señal en 3 niveles: fuerte, media y débil.
//   - Se buscan redes mientras alguien mire la lista (el Centro de control
//     o Ajustes) y el Wi-Fi esté encendido. Con un contador, no con un
//     sí/no: si los dos miran y uno se cierra, el otro sigue viendo la lista
//     al día.

pragma Singleton

import QtQuick
import Quickshell
import qs.data.network

Singleton {
    id: root

    readonly property bool available: NetworkRepository.hasWifi
    readonly property bool powered: NetworkRepository.wifiEnabled
    readonly property bool wired: NetworkRepository.wiredConnected

    readonly property var networks: {
        // Una entrada por nombre.
        const best = {};
        for (const network of NetworkRepository.networks) {
            if (!network.name)
                continue;

            const previous = best[network.name];
            if (!previous
                || network.connected
                || (!previous.connected && network.strength > previous.strength))
                best[network.name] = network;
        }

        return Object.values(best)
            .map(network => Object.assign({}, network, {
                level: root.levelOf(network.strength),
                needsPassword: !network.open && !network.known,
                detail: root.detailOf(network)
            }))
            .sort((a, b) => (b.connected - a.connected)
                            || (b.known - a.known)
                            || (b.strength - a.strength));
    }

    readonly property var current: root.networks.find(n => n.connected) ?? null

    readonly property var known: root.networks.filter(n => n.known || n.connected)
    readonly property var others: root.networks.filter(n => !n.known && !n.connected)

    // Estado bajo el título del mosaico.
    readonly property string status: {
        if (!root.available)
            return root.wired ? "Ethernet" : "No disponible";
        if (!root.powered)
            return "Desactivado";
        if (root.current)
            return root.current.name;
        return root.wired ? "Ethernet" : "Sin conexión";
    }

    // Ícono del mosaico.
    readonly property string level: {
        if (!root.available || !root.powered)
            return "off";
        if (!root.current)
            return "none";
        return root.current.level;
    }

    property int scanWatchers: 0

    // Igual que la búsqueda de Bluetooth: se deriva, no se ordena.
    readonly property bool scanning: root.scanWatchers > 0 && root.powered
    onScanningChanged: NetworkRepository.setScanning(root.scanning)

    // Cuando cambia qué redes son conocidas o cuál es la actual, los perfiles
    // y la IP ya no son los mismos: se releen (si alguien está mirando).
    readonly property string knownKey: root.known.map(n => n.name + (n.connected ? "*" : "")).join("|")
    onKnownKeyChanged: {
        if (root.scanWatchers > 0)
            WifiProfiles.refreshSoon();
    }

    function find(name) {
        return root.networks.find(n => n.name === name) ?? null;
    }

    function setPowered(on): void {
        NetworkRepository.setWifiEnabled(on);
    }

    function toggle(): void {
        root.setPowered(!root.powered);
    }

    function startScan(): void {
        root.scanWatchers++;
        WifiProfiles.refresh();
    }

    function stopScan(): void {
        root.scanWatchers = Math.max(0, root.scanWatchers - 1);
    }

    function choose(name): void {
        const network = root.find(name);
        if (!network || network.connected)
            return;

        if (network.needsPassword) {
            root.joinError = network.enterprise
                ? "Esta red es de empresa: pide usuario y certificado, no solo contraseña. "
                  + "Configúrala con nm-connection-editor o nmtui."
                : "";
            root.passwordNeededFor = name;
            return;
        }

        NetworkRepository.connectTo(name);
    }

    function disconnect(name): void {
        NetworkRepository.disconnectFrom(name);
    }

    // ── contraseña ───────────────────────────────────────────────
    //
    // La red que está pidiendo contraseña ("" si ninguna), si se está
    // intentando entrar, y por qué falló el último intento.
    property string passwordNeededFor: ""
    readonly property bool joining: WifiProfiles.joining
    property string joinError: ""

    // Lo que la hoja necesita saber de esa red.
    readonly property var asking: {
        if (root.passwordNeededFor === "")
            return null;

        const network = root.find(root.passwordNeededFor);
        return {
            name: root.passwordNeededFor,
            security: network?.security ?? "",
            enterprise: network?.enterprise ?? false,
            // WPA no acepta menos de 8 caracteres: ni se intenta.
            minimumLength: (network?.security ?? "").indexOf("WPA") === 0 ? 8 : 1
        };
    }

    function submitPassword(password): void {
        if (!root.asking || root.asking.enterprise || root.joining)
            return;
        if (password.length < root.asking.minimumLength)
            return;

        root.joinError = "";
        WifiProfiles.join(root.passwordNeededFor, password);
    }

    function cancelPassword(): void {
        root.passwordNeededFor = "";
        root.joinError = "";
    }

    Connections {
        target: WifiProfiles

        function onJoined(name) {
            if (name === root.passwordNeededFor)
                root.cancelPassword();
        }

        // Si ya cancelaste, el fallo no le importa a nadie.
        function onJoinFailed(name, reason, detail) {
            if (name !== root.passwordNeededFor)
                return;

            root.joinError = ({
                password: "La contraseña no es correcta.",
                gone: "La red ya no está al alcance.",
                timeout: "La red no respondió a tiempo. Intenta de nuevo."
            })[reason] ?? ("No se pudo conectar. " + detail);
        }
    }

    // ── detalles ─────────────────────────────────────────────────
    property string detailsFor: ""

    // Por qué no se pudo guardar el borrador ("" si todo bien).
    property string detailsError: ""

    // Todo lo que enseña la hoja de detalles, o null si no hay ninguna
    // abierta (o la red dejó de verse). Tres orígenes, ya mezclados:
    //   - la red (nombre, señal, seguridad): NetworkRepository;
    //   - el perfil guardado (lo que se puede editar): WifiProfiles;
    //   - el enlace (lo que la tarjeta tiene AHORA): solo si es la red en uso.
    // Lo editable lleva el mismo nombre en el borrador de la hoja.
    readonly property var details: {
        const network = root.detailsFor === "" ? null : root.find(root.detailsFor);
        if (!network)
            return null;

        const profile = WifiProfiles.profiles[network.name] ?? null;
        const stored = WifiProfiles.settings && WifiProfiles.settings.name === network.name
            ? WifiProfiles.settings : null;
        const link = network.connected ? WifiProfiles.link : WifiProfiles.noLink;
        const manual = stored !== null && stored.ipv4Method === "manual";

        return {
            name: network.name,
            connected: network.connected,
            status: network.detail,
            level: network.level,
            security: network.open ? "Ninguna" : (network.security || "Con contraseña"),
            enterprise: network.enterprise,
            // Sin perfil no hay nada que ajustar ni que olvidar.
            saved: profile !== null,
            // Ya llegaron los ajustes completos (IP, DNS, proxy...).
            loaded: stored !== null,

            // La red.
            autoJoin: profile?.autoconnect ?? true,
            privateAddress: profile?.privateAddress ?? "off",
            lowData: profile?.metered ?? false,
            limitTracking: stored?.ip6Privacy ?? false,
            address: link.mac,

            // TCP/IP. En manual se enseña lo guardado; si no, lo que dio el
            // router (así, al pasar a "Manualmente", ya viene lleno).
            ipv4Method: stored?.ipv4Method ?? "auto",
            ipv4Address: manual ? stored.ipv4Address : link.ip,
            ipv4Mask: root.maskOf(manual ? stored.ipv4Prefix : link.prefix),
            ipv4Router: manual ? stored.ipv4Router : link.router,
            ipv6Method: stored?.ipv6Method ?? "auto",
            ipv6Addresses: link.ip6 !== "" ? [link.ip6] : [],
            ipv6Router: link.router6,

            // DNS: los tuyos; si no hay, se usan los del router (liveDns).
            dnsServers: stored?.dns ?? [],
            searchDomains: stored?.searchDomains ?? [],
            liveDns: link.dns,

            // WINS no existe en NetworkManager: solo el nombre del equipo.
            hostname: WifiProfiles.host.name,
            workgroup: WifiProfiles.host.workgroup,
            winsServer: WifiProfiles.host.wins,

            // 802.1X (solo lectura).
            eap: stored?.eap ?? "",
            identity: stored?.identity ?? "",

            // Proxy: automático sin URL = descubrirlo (WPAD); con URL = PAC.
            proxyDiscovery: (stored?.proxyAuto ?? false) && stored.pacUrl === "",
            proxyPac: (stored?.proxyAuto ?? false) && stored.pacUrl !== "",
            pacUrl: stored?.pacUrl ?? "",

            // Hardware.
            mtuAuto: (stored?.mtu ?? 0) === 0,
            mtu: (stored?.mtu ?? 0) || link.mtu || 1500,
            liveMtu: link.mtu
        };
    }

    // Lo que la hoja copia a su borrador y devuelve en saveDetails().
    readonly property var editableKeys: [
        "autoJoin", "privateAddress", "lowData", "limitTracking",
        "ipv4Method", "ipv4Address", "ipv4Mask", "ipv4Router", "ipv6Method",
        "dnsServers", "searchDomains",
        "proxyDiscovery", "proxyPac", "pacUrl",
        "mtuAuto", "mtu"
    ]

    function openDetails(name): void {
        root.detailsError = "";
        WifiProfiles.refresh();
        WifiProfiles.readSettings(name);
        root.detailsFor = name;
    }

    function closeDetails(): void {
        root.detailsFor = "";
        root.detailsError = "";
        WifiProfiles.readSettings("");
    }

    // Si se abrió antes de que llegaran los perfiles, se pide en cuanto estén.
    Connections {
        target: WifiProfiles

        function onProfilesChanged() {
            if (root.detailsFor !== "" && WifiProfiles.settings === null)
                WifiProfiles.readSettings(root.detailsFor);
        }
    }

    // Vuelve a levantar la conexión: renueva la concesión DHCP.
    function renewLease(): void {
        if (root.details && root.details.connected)
            WifiProfiles.reactivate(root.details.name);
    }

    // draft: el borrador de la hoja (las editableKeys). Se revisa, se manda
    // solo lo que cambió y se cierra. Si algo está mal escrito, la hoja se
    // queda abierta con el motivo en detailsError.
    function saveDetails(draft): void {
        const now = root.details;
        if (!now || !now.saved || !now.loaded) {
            root.closeDetails();
            return;
        }

        const dns = draft.dnsServers.map(entry => entry.trim()).filter(entry => entry !== "");
        const domains = draft.searchDomains.map(entry => entry.trim()).filter(entry => entry !== "");
        const pacUrl = draft.pacUrl.trim();
        const mtu = parseInt(draft.mtu);
        const prefix = root.prefixOf(draft.ipv4Mask);

        // ── revisar ──
        let error = "";
        if (draft.ipv4Method === "manual") {
            if (!root.isIpv4(draft.ipv4Address))
                error = "TCP/IP: la dirección IP no es válida.";
            else if (prefix < 1)
                error = "TCP/IP: la máscara de subred no es válida (ejemplo: 255.255.255.0).";
            else if (draft.ipv4Router.trim() !== "" && !root.isIpv4(draft.ipv4Router))
                error = "TCP/IP: la dirección del router no es válida.";
        }
        if (error === "" && dns.some(entry => !root.isIpv4(entry) && !root.isIpv6(entry)))
            error = "DNS: «" + dns.find(entry => !root.isIpv4(entry) && !root.isIpv6(entry))
                    + "» no es una dirección IP.";
        if (error === "" && domains.some(entry => /\s/.test(entry)))
            error = "DNS: un dominio de búsqueda no lleva espacios.";
        if (error === "" && draft.proxyPac && !/^(https?|file):\/\/\S+$/.test(pacUrl))
            error = "Proxies: escribe la URL del archivo de configuración (http://…).";
        if (error === "" && !draft.mtuAuto && !(mtu >= 576 && mtu <= 9000))
            error = "Hardware: la MTU va de 576 a 9000.";

        if (error !== "") {
            root.detailsError = error;
            return;
        }

        // ── qué cambió ──
        const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
        const changes = {};
        // Lo de red no lo toma una conexión ya hecha: hay que relevantarla.
        let network = false;

        if (draft.autoJoin !== now.autoJoin)
            changes.autoconnect = draft.autoJoin;
        if (draft.lowData !== now.lowData)
            changes.metered = draft.lowData;
        if (draft.privateAddress !== now.privateAddress)
            changes.privateAddress = draft.privateAddress;

        if (draft.limitTracking !== now.limitTracking) {
            changes.ip6Privacy = draft.limitTracking;
            network = true;
        }

        const ipv4 = draft.ipv4Method === "manual"
            ? [draft.ipv4Method, draft.ipv4Address.trim(), prefix, draft.ipv4Router.trim()]
            : [draft.ipv4Method];
        const ipv4Now = now.ipv4Method === "manual"
            ? [now.ipv4Method, now.ipv4Address, root.prefixOf(now.ipv4Mask), now.ipv4Router]
            : [now.ipv4Method];
        if (!same(ipv4, ipv4Now)) {
            changes.ipv4 = { method: ipv4[0], address: ipv4[1] ?? "", prefix: ipv4[2] ?? 0, router: ipv4[3] ?? "" };
            network = true;
        }

        if (draft.ipv6Method !== now.ipv6Method) {
            changes.ipv6Method = draft.ipv6Method;
            network = true;
        }
        if (!same(dns, now.dnsServers)) {
            changes.dns = dns;
            network = true;
        }
        if (!same(domains, now.searchDomains)) {
            changes.searchDomains = domains;
            network = true;
        }

        const proxy = [draft.proxyDiscovery || draft.proxyPac, draft.proxyPac ? pacUrl : ""];
        const proxyNow = [now.proxyDiscovery || now.proxyPac, now.proxyPac ? now.pacUrl : ""];
        if (!same(proxy, proxyNow)) {
            changes.proxy = { auto: proxy[0], pacUrl: proxy[1] };
            network = true;
        }

        const wantedMtu = draft.mtuAuto ? 0 : mtu;
        const mtuNow = now.mtuAuto ? 0 : now.mtu;
        if (wantedMtu !== mtuNow) {
            changes.mtu = wantedMtu;
            network = true;
        }

        WifiProfiles.update(now.name, changes, network && now.connected);
        root.closeDetails();
    }

    // ── direcciones ──────────────────────────────────────────────
    function isIpv4(text) {
        const parts = String(text).trim().split(".");
        return parts.length === 4 && parts.every(part => /^\d{1,3}$/.test(part) && parseInt(part) <= 255);
    }

    // Sin afinar: hexadecimales y dos puntos, con al menos dos ":".
    function isIpv6(text) {
        const value = String(text).trim();
        return /^[0-9a-fA-F:.]+$/.test(value) && value.split(":").length >= 3;
    }

    // 24 → "255.255.255.0". Cada trozo son 8 bits del prefijo.
    function maskOf(prefix) {
        if (!(prefix >= 1 && prefix <= 32))
            return "";

        const parts = [];
        for (let i = 0; i < 4; i++) {
            const bits = Math.max(0, Math.min(8, prefix - i * 8));
            parts.push(256 - Math.pow(2, 8 - bits));
        }
        return parts.join(".");
    }

    // "255.255.255.0" → 24. Devuelve -1 si no es una máscara (unos seguidos
    // y luego ceros). También acepta el prefijo tal cual: "24" o "/24".
    function prefixOf(mask) {
        const value = String(mask).trim();
        const plain = /^\/?(\d{1,2})$/.exec(value);
        if (plain)
            return parseInt(plain[1]) >= 1 && parseInt(plain[1]) <= 32 ? parseInt(plain[1]) : -1;
        if (!root.isIpv4(value))
            return -1;

        const bits = value.split(".").map(part => parseInt(part).toString(2).padStart(8, "0")).join("");
        return /^1+0*$/.test(bits) ? bits.indexOf("0") < 0 ? 32 : bits.indexOf("0") : -1;
    }

    // ── olvidar ──────────────────────────────────────────────────
    //
    // La red que espera el "¿Eliminar?" ("" si ninguna).
    property string forgetting: ""

    function askForget(name): void {
        root.forgetting = name;
    }

    function confirmForget(): void {
        if (root.forgetting === "")
            return;

        WifiProfiles.forget(root.forgetting);
        if (root.detailsFor === root.forgetting)
            root.closeDetails();
        root.forgetting = "";
    }

    function cancelForget(): void {
        root.forgetting = "";
    }

    function levelOf(strength) {
        if (strength >= 0.66)
            return "high";
        if (strength >= 0.33)
            return "medium";
        return "low";
    }

    function detailOf(network) {
        if (network.busy)
            return network.connected ? "Desconectando…" : "Conectando…";
        if (network.connected)
            return "Conectada";
        if (network.known)
            return "Conocida";
        return "";
    }
}
