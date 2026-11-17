// REGLAS de los ajustes de una conexión (TCP/IP, DNS, proxy, MTU), las
// mismas para Wi-Fi y para Ethernet. Son funciones puras: reciben datos y
// devuelven datos, sin estado ni llamadas a nadie. WifiControl y
// EthernetControl las usan para armar y guardar su hoja de "Detalles…".
//
//   - shared(stored, link, host): la parte de los detalles que es igual en
//     toda conexión, con lo guardado (perfil) y lo que hay ahora (enlace).
//   - check(draft): por qué no se puede guardar el borrador ("" si se puede).
//   - tcpipProblem(draft): solo lo de TCP/IP, para avisar mientras escribes.
//   - diff(draft, now): qué cambió, y si hay que relevantar la conexión.
//
// Tener las reglas en un solo lugar es lo que hace que la hoja de Ethernet
// y la de Wi-Fi se porten igual: no hay dos copias que se puedan desfasar.

pragma Singleton

import QtQuick
import Quickshell

Singleton {
    id: root

    // Lo que la hoja copia a su borrador y devuelve al guardar, en toda
    // conexión. Cada caso de uso le suma lo suyo (Wi-Fi: autoJoin...).
    readonly property var editableKeys: [
        "limitTracking",
        "ipv4Method", "ipv4Address", "ipv4Mask", "ipv4Router", "dhcpClientId", "ipv6Method",
        "dnsServers", "searchDomains",
        "proxyDiscovery", "proxyPac", "pacUrl",
        "mtuAuto", "mtu"
    ]

    // stored: el perfil guardado (o null); link: lo que la tarjeta tiene
    // ahora (vacío si esta conexión no está en uso); host: nombre del equipo.
    function shared(stored: var, link: var, host: var): var {
        const manual = stored !== null && stored.ipv4Method === "manual";

        return {
            limitTracking: stored?.ip6Privacy ?? false,
            address: link.mac,

            // TCP/IP. En manual se enseña lo guardado; si no, lo que dio el
            // router (así, al pasar a "Manualmente", ya viene lleno).
            ipv4Method: stored?.ipv4Method ?? "auto",
            ipv4Address: manual ? stored.ipv4Address : link.ip,
            ipv4Mask: root.maskOf(manual ? stored.ipv4Prefix : link.prefix),
            ipv4Router: manual ? stored.ipv4Router : link.router,
            dhcpClientId: stored?.dhcpClientId ?? "",
            ipv6Method: stored?.ipv6Method ?? "auto",
            ipv6Addresses: link.ip6 !== "" ? [link.ip6] : [],
            ipv6Router: link.router6,

            // DNS: los tuyos; si no hay, se usan los del router (liveDns).
            dnsServers: stored?.dns ?? [],
            searchDomains: stored?.searchDomains ?? [],
            liveDns: link.dns,
            liveDomains: link.domains,

            // WINS no existe en NetworkManager: solo el nombre del equipo.
            hostname: host.name,
            workgroup: host.workgroup,
            winsServer: host.wins,

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

    function clean(list: var): var {
        return list.map(entry => entry.trim()).filter(entry => entry !== "");
    }

    // Lo de TCP/IP que está mal escrito ("" si nada). Solo importa en manual.
    function tcpipProblem(draft: var): string {
        if (draft.ipv4Method !== "manual")
            return "";
        if (!root.isIpv4(draft.ipv4Address))
            return "TCP/IP: la dirección IP no es válida.";
        if (root.prefixOf(draft.ipv4Mask) < 1)
            return "TCP/IP: la máscara de subred no es válida (ejemplo: 255.255.255.0).";
        if (draft.ipv4Router.trim() !== "" && !root.isIpv4(draft.ipv4Router))
            return "TCP/IP: la dirección del router no es válida.";
        return "";
    }

    function check(draft: var): string {
        const tcpip = root.tcpipProblem(draft);
        if (tcpip !== "")
            return tcpip;

        const bad = root.clean(draft.dnsServers).find(entry => !root.isIpv4(entry) && !root.isIpv6(entry));
        if (bad !== undefined)
            return "DNS: «" + bad + "» no es una dirección IP.";
        if (root.clean(draft.searchDomains).some(entry => /\s/.test(entry)))
            return "DNS: un dominio de búsqueda no lleva espacios.";
        if (draft.proxyPac && !/^(https?|file):\/\/\S+$/.test(draft.pacUrl.trim()))
            return "Proxies: escribe la URL del archivo de configuración (http://…).";

        const mtu = parseInt(draft.mtu);
        if (!draft.mtuAuto && !(mtu >= 576 && mtu <= 9000))
            return "Hardware: la MTU va de 576 a 9000.";
        return "";
    }

    // Compara el borrador (ya revisado) con lo que hay y devuelve
    // { changes, network }: los cambios con los nombres que entiende el
    // repositorio, y si alguno es "de red". Lo de red (IP, DNS, proxy, MTU)
    // no lo toma una conexión ya hecha: hay que volver a levantarla.
    function diff(draft: var, now: var): var {
        const same = (a, b) => JSON.stringify(a) === JSON.stringify(b);
        const changes = {};
        let network = false;

        if (draft.limitTracking !== now.limitTracking) {
            changes.ip6Privacy = draft.limitTracking;
            network = true;
        }

        const ipv4 = draft.ipv4Method === "manual"
            ? [draft.ipv4Method, draft.ipv4Address.trim(), root.prefixOf(draft.ipv4Mask), draft.ipv4Router.trim()]
            : [draft.ipv4Method];
        const ipv4Now = now.ipv4Method === "manual"
            ? [now.ipv4Method, now.ipv4Address, root.prefixOf(now.ipv4Mask), now.ipv4Router]
            : [now.ipv4Method];
        if (!same(ipv4, ipv4Now)) {
            changes.ipv4 = { method: ipv4[0], address: ipv4[1] ?? "", prefix: ipv4[2] ?? 0, router: ipv4[3] ?? "" };
            network = true;
        }

        // El identificador de cliente solo sirve con DHCP.
        const clientId = draft.ipv4Method === "auto" ? draft.dhcpClientId.trim() : now.dhcpClientId;
        if (clientId !== now.dhcpClientId) {
            changes.dhcpClientId = clientId;
            network = true;
        }

        if (draft.ipv6Method !== now.ipv6Method) {
            changes.ipv6Method = draft.ipv6Method;
            network = true;
        }

        const dns = root.clean(draft.dnsServers);
        if (!same(dns, now.dnsServers)) {
            changes.dns = dns;
            network = true;
        }

        const domains = root.clean(draft.searchDomains);
        if (!same(domains, now.searchDomains)) {
            changes.searchDomains = domains;
            network = true;
        }

        const proxy = [draft.proxyDiscovery || draft.proxyPac, draft.proxyPac ? draft.pacUrl.trim() : ""];
        const proxyNow = [now.proxyDiscovery || now.proxyPac, now.proxyPac ? now.pacUrl : ""];
        if (!same(proxy, proxyNow)) {
            changes.proxy = { auto: proxy[0], pacUrl: proxy[1] };
            network = true;
        }

        const mtu = draft.mtuAuto ? 0 : parseInt(draft.mtu);
        if (mtu !== (now.mtuAuto ? 0 : now.mtu)) {
            changes.mtu = mtu;
            network = true;
        }

        return { changes: changes, network: network };
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
}
