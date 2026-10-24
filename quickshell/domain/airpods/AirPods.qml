// CASO DE USO: tus AirPods.
// Reglas:
//   - "Tus AirPods" son el dispositivo Bluetooth conectado cuyo nombre dice
//     AirPods o Beats. Si les cambiaste el nombre y LibrePods está corriendo,
//     cuentan los primeros audífonos conectados.
//   - Los controles (modo de ruido, detección de conversación, batería de
//     cada pieza) salen de LibrePods. Sin LibrePods siguen siendo audífonos
//     normales: se conectan y suenan, pero sin esas opciones.
//   - Modos de ruido en el orden de macOS: Desactivado, Transparencia,
//     Adaptativo, Cancelación de ruido. Solo los que LibrePods ofrece
//     ("Desactivado" aparece si lo habilitas en la ventana de LibrePods:
//     "Off Listening Mode").
//   - Batería: izquierdo, derecho y estuche; una sola si son AirPods Max.
//     Lo que LibrePods todavía no sabe no se muestra.
//   - Al conectarse, el sonido se pasa a ellos, como en macOS. Una vez por
//     conexión: si luego eliges otra salida, se respeta. No hace falta
//     LibrePods.

pragma Singleton

import QtQuick
import Quickshell
import qs.data.airpods
import qs.data.audio
import qs.domain.bluetooth

Singleton {
    id: root

    // Cada modo: cómo lo llamamos y cómo lo reconoce en el menú de LibrePods
    // (las dos versiones lo escriben en inglés).
    readonly property var catalog: [
        { id: "off",          label: "Desactivado",          short: "Desactivado",   match: /^off$/i },
        { id: "transparency", label: "Transparencia",        short: "Transparencia", match: /transparen/i },
        { id: "adaptive",     label: "Adaptativo",           short: "Adaptativo",    match: /adaptive/i },
        { id: "anc",          label: "Cancelación de ruido", short: "Cancelación",   match: /noise|cancel/i }
    ]

    // ── el dispositivo ────────────────────────────────────────────

    function isAirPods(device): bool {
        return !!device && /airpods|beats/i.test(device.name || "");
    }

    readonly property var device: {
        const connected = BluetoothControl.connected;
        const named = connected.find(d => root.isAirPods(d));
        if (named)
            return named;

        // Renombrados: si LibrePods corre y sabe la batería, son los audífonos.
        if (root.controllable && root.pieces.length > 0)
            return connected.find(d => d.kind === "headphones") ?? null;

        return null;
    }

    readonly property bool connected: root.device !== null
    readonly property string name: root.device ? root.device.name : "AirPods"
    readonly property string address: root.device ? root.device.address : ""

    // ¿se pueden controlar? = LibrePods está corriendo.
    readonly property bool controllable: LibrePodsRepository.running

    // ¿está instalado? Para explicar en Ajustes qué falta.
    readonly property bool installed: LibrePodsRepository.installed

    // ¿tu PC se presenta como un aparato de Apple? (modo Apple, lo pone
    // ./install.sh --airpods si dices que sí). Solo se enseña: cambiarlo
    // reinicia Bluetooth y pide contraseña, así que vive en el install.
    readonly property bool appleMode: LibrePodsRepository.appleMode

    function refreshAppleMode(): void {
        LibrePodsRepository.refreshAppleMode();
    }

    // ¿este dispositivo de la lista de Bluetooth son tus AirPods?
    function owns(device): bool {
        return root.connected && !!device && device.address === root.address;
    }

    // ── modos de ruido ────────────────────────────────────────────

    // Cada modo que LibrePods ofrece, con el texto exacto de su menú.
    readonly property var modes: {
        const entries = LibrePodsRepository.entries;
        const out = [];

        for (let i = 0; i < root.catalog.length; ++i) {
            const mode = root.catalog[i];
            const entry = entries.find(e => e.checkable && mode.match.test(e.text));
            if (entry) {
                out.push({
                    id: mode.id,
                    label: mode.label,
                    short: mode.short,
                    text: entry.text,
                    enabled: entry.enabled,
                    active: entry.checked
                });
            }
        }

        return out;
    }

    readonly property string mode: root.modes.find(m => m.active)?.id ?? ""
    readonly property string modeLabel: root.modes.find(m => m.active)?.label ?? ""

    function setMode(id): void {
        const mode = root.modes.find(m => m.id === id);
        if (mode && mode.enabled && !mode.active)
            LibrePodsRepository.trigger(mode.text);
    }

    // ── detección de conversación ─────────────────────────────────
    //
    // Baja el volumen y deja pasar tu voz cuando empiezas a hablar.
    readonly property var conversationEntry: LibrePodsRepository.entries
        .find(e => e.checkable && /convers/i.test(e.text)) ?? null

    readonly property bool hasConversation: root.conversationEntry !== null
                                            && root.conversationEntry.enabled
    readonly property bool conversation: root.conversationEntry?.checked ?? false

    function toggleConversation(): void {
        if (root.hasConversation)
            LibrePodsRepository.trigger(root.conversationEntry.text);
    }

    // ── batería ───────────────────────────────────────────────────
    //
    // Del tooltip de LibrePods. Una pieza: { id, label, level (0 a 1),
    // charging }. Las que vienen "-" o "?" (desconectada, aún no se sabe) no
    // entran.
    readonly property var pieces: root.parseBattery(LibrePodsRepository.batteryText)

    readonly property real lowest: root.pieces
        .filter(p => p.id !== "case")
        .reduce((min, p) => Math.min(min, p.level), 1)

    function parseBattery(text) {
        const labels = {
            left: "Izquierdo", right: "Derecho", case: "Estuche", headset: "Audífonos"
        };
        const keys = { l: "left", left: "left", r: "right", right: "right",
                       c: "case", case: "case", headset: "headset" };

        const found = {};
        const pattern = /\b(Left|Right|Case|Headset|L|R|C)\s*:\s*(\d{1,3})\s*%\s*(⚡)?/gi;
        let match;

        while ((match = pattern.exec(String(text || ""))) !== null) {
            const id = keys[match[1].toLowerCase()];
            if (id && !(id in found))
                found[id] = { level: Math.min(100, parseInt(match[2])) / 100, charging: !!match[3] };
        }

        return ["left", "right", "case", "headset"]
            .filter(id => id in found)
            .map(id => ({ id: id, label: labels[id], level: found[id].level,
                          charging: found[id].charging }));
    }

    // ── el sonido ─────────────────────────────────────────────────
    //
    // PipeWire no cambia de salida solo si alguna vez elegiste otra a mano: se
    // queda con esa, y los AirPods conectan pero no suenan. Su salida es el
    // nodo "bluez_output.<su dirección, con _>…".
    readonly property var output: {
        if (!root.connected || root.address === "")
            return null;

        const key = root.address.replace(/:/g, "_").toUpperCase();
        return AudioRepository.outputs.find(o => o.name.toUpperCase().indexOf(key) >= 0) ?? null;
    }

    // A qué AirPods ya se les pasó el sonido en esta conexión.
    property string routedTo: ""

    // Al arrancar la shell no se toca la salida: si ya estaban conectados,
    // lo que suena ahora es lo que elegiste.
    property bool armed: false

    Timer {
        interval: 3000
        running: true
        onTriggered: {
            if (root.output)
                root.routedTo = root.address;
            root.armed = true;
        }
    }

    onOutputChanged: {
        if (!root.output) {
            if (!root.connected)
                root.routedTo = "";
            return;
        }

        if (!root.armed || root.routedTo === root.address)
            return;

        root.routedTo = root.address;
        if (AudioRepository.currentOutputId !== root.output.id)
            AudioRepository.setOutput(root.output.id);
    }

    // ── LibrePods ─────────────────────────────────────────────────

    // Su ventana, para lo que tu shell no cubre (renombrarlos, volumen
    // personalizado, controles del tallo…). Es la opción "Open…" de su menú.
    function openApp(): void {
        const entry = LibrePodsRepository.entries.find(e => /^open/i.test(e.text));
        if (entry)
            LibrePodsRepository.trigger(entry.text);
        else if (!root.controllable)
            LibrePodsRepository.start();
    }
}
