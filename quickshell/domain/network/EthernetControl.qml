// CASO DE USO: la red por cable (Ajustes › Red).
// Reglas:
//   - Un SERVICIO por tarjeta de cable, como en macOS. Su perfil es el que
//     está usando; si no usa ninguno, el guardado para esa tarjeta, y si
//     tampoco, el primero que sirva para cualquiera.
//   - El servicio se llama como su perfil; sin perfil, como la tarjeta.
//   - Estados: Conectado (verde), Conectando… (ámbar), Inactivo (lo
//     desactivaste, gris) y Sin cable (rojo).
//   - El resumen enseña lo que la tarjeta tiene AHORA; si está en manual, lo
//     que guardaste.
//   - Los detalles se editan en borrador y se guardan con Aceptar; las
//     reglas de qué es válido son las de ConnectionSettings, las mismas del
//     Wi-Fi. Si la conexión está en uso y cambió algo de red, se relevanta.
//   - Eliminar el servicio siempre pasa por una confirmación.
//   - Mientras alguien mira la página se relee cada pocos segundos:
//     NetworkManager no avisa aquí cuando enchufas o quitas el cable.

pragma Singleton

import QtQuick
import Quickshell
import qs.data.network

Singleton {
    id: root

    readonly property bool loaded: WiredRepository.loaded

    readonly property var services: WiredRepository.devices.map(device => {
        const profile = root.profileFor(device);
        const stored = profile;
        const manual = stored !== null && stored.ipv4Method === "manual";

        return {
            device: device.device,
            name: profile?.id || device.connection || device.product || device.device,
            state: device.state,
            connected: device.state === "connected",
            // "Activo" = NetworkManager lo está usando o intentando usar.
            active: device.state === "connected" || device.state === "connecting",
            status: root.statusOf(device.state),
            saved: profile !== null,
            uuid: profile?.uuid ?? "",

            // El resumen de la página.
            ipv4Method: stored?.ipv4Method ?? "auto",
            ip: manual ? stored.ipv4Address : device.ip,
            mask: ConnectionSettings.maskOf(manual ? stored.ipv4Prefix : device.prefix),
            router: manual ? stored.ipv4Router : device.router,
            dns: (stored !== null && stored.dns.length > 0 ? stored.dns : device.dns).join(", "),
            domains: (stored !== null && stored.searchDomains.length > 0
                      ? stored.searchDomains : device.domains).join(", ")
        };
    })

    // El servicio a la vista. Con una sola tarjeta, esa.
    property string selected: ""
    readonly property var current: root.find(root.selected) ?? root.services[0] ?? null

    function find(device) {
        return root.services.find(service => service.device === device) ?? null;
    }

    function select(device): void {
        root.selected = device;
    }

    function profileFor(device) {
        const profiles = WiredRepository.profiles;
        return (device.uuid !== "" ? WiredRepository.find(device.uuid) : null)
            ?? profiles.find(profile => profile.interfaceName === device.device)
            ?? profiles.find(profile => profile.interfaceName === "")
            ?? null;
    }

    function statusOf(state) {
        return ({
            connected: "Conectado",
            connecting: "Conectando…",
            disconnected: "Inactivo",
            unavailable: "Sin cable"
        })[state] ?? "Sin cable";
    }

    // ── quién mira ───────────────────────────────────────────────
    property int watchers: 0

    function startWatching(): void {
        root.watchers++;
        WiredRepository.refresh();
    }

    function stopWatching(): void {
        root.watchers = Math.max(0, root.watchers - 1);
    }

    Timer {
        interval: 4000
        repeat: true
        running: root.watchers > 0
        onTriggered: WiredRepository.refresh()
    }

    // ── activar y eliminar ───────────────────────────────────────
    function setActive(device, on): void {
        WiredRepository.setActive(device, on);
    }

    // El servicio que espera el "¿Eliminar?" ("" si ninguno).
    property string deleting: ""

    function askDelete(device): void {
        if (root.find(device)?.saved)
            root.deleting = device;
    }

    function confirmDelete(): void {
        const service = root.find(root.deleting);
        if (service && service.saved)
            WiredRepository.remove(service.uuid);
        if (root.detailsFor === root.deleting)
            root.closeDetails();
        root.deleting = "";
    }

    function cancelDelete(): void {
        root.deleting = "";
    }

    // ── detalles ─────────────────────────────────────────────────
    //
    // Misma forma que en WifiControl (details, editableKeys, detailsError,
    // saveDetails...): por eso las dos usan la misma hoja.
    property string detailsFor: ""
    property string detailsError: ""

    readonly property var details: {
        const service = root.detailsFor === "" ? null : root.find(root.detailsFor);
        if (!service)
            return null;

        const stored = service.saved ? WiredRepository.find(service.uuid) : null;
        const device = WiredRepository.devices.find(entry => entry.device === service.device);
        // Lo del enlace solo vale mientras la conexión está hecha.
        const link = service.connected ? device : Object.assign({}, WifiProfiles.noLink, { mac: device.mac, mtu: device.mtu });

        return Object.assign(ConnectionSettings.shared(stored, link, WifiProfiles.host), {
            name: service.name,
            device: service.device,
            connected: service.connected,
            state: service.state,
            status: service.status,
            security: "Ninguna",
            enterprise: false,
            saved: stored !== null,
            loaded: stored !== null
        });
    }

    readonly property var editableKeys: ConnectionSettings.editableKeys

    function openDetails(device): void {
        root.detailsError = "";
        WiredRepository.refresh();
        root.detailsFor = device;
    }

    function closeDetails(): void {
        root.detailsFor = "";
        root.detailsError = "";
    }

    function renewLease(): void {
        const service = root.find(root.detailsFor);
        if (service && service.connected && service.saved)
            WiredRepository.reactivate(service.uuid);
    }

    function saveDetails(draft): void {
        const now = root.details;
        const service = root.find(root.detailsFor);
        if (!now || !now.saved || !service) {
            root.closeDetails();
            return;
        }

        const error = ConnectionSettings.check(draft);
        if (error !== "") {
            root.detailsError = error;
            return;
        }

        const result = ConnectionSettings.diff(draft, now);
        WiredRepository.update(service.uuid, result.changes, result.network && now.connected);
        root.closeDetails();
    }
}
