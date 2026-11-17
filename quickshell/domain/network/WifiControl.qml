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

    // Todo lo que enseña la hoja de detalles, o null si no hay ninguna
    // abierta (o la red dejó de verse).
    readonly property var details: {
        const network = root.detailsFor === "" ? null : root.find(root.detailsFor);
        if (!network)
            return null;

        const profile = WifiProfiles.profiles[network.name] ?? null;
        const link = WifiProfiles.link;

        return {
            name: network.name,
            connected: network.connected,
            status: network.detail,
            level: network.level,
            security: network.open ? "Ninguna" : (network.security || "Con contraseña"),
            // Sin perfil no hay nada que ajustar ni que olvidar.
            saved: profile !== null,
            autoJoin: profile?.autoconnect ?? true,
            privateAddress: profile?.privateAddress ?? "off",
            lowData: profile?.metered ?? false,
            // Lo del enlace solo es de esta red si es la conectada.
            address: network.connected ? link.mac : "",
            ip: network.connected ? link.ip : "",
            router: network.connected ? link.router : "",
            dns: network.connected ? link.dns.join(", ") : ""
        };
    }

    function openDetails(name): void {
        WifiProfiles.refresh();
        root.detailsFor = name;
    }

    function closeDetails(): void {
        root.detailsFor = "";
    }

    // draft: { autoJoin, privateAddress, lowData }, lo que quedó en la hoja.
    function saveDetails(draft): void {
        const now = root.details;
        if (now && now.saved) {
            const changes = {};
            if (draft.autoJoin !== now.autoJoin)
                changes.autoconnect = draft.autoJoin;
            if (draft.lowData !== now.lowData)
                changes.metered = draft.lowData;
            if (draft.privateAddress !== now.privateAddress)
                changes.privateAddress = draft.privateAddress;

            WifiProfiles.update(now.name, changes);
        }

        root.closeDetails();
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
