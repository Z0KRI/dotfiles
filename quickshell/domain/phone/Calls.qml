// CASO DE USO: la llamada del iPhone que está pasando por la PC (con
// ./install.sh --calls el audio viene a la computadora).
// Reglas:
//   - "En curso" = activa, en espera, o marcando / sonando del otro lado. La
//     que suena AQUÍ (entrante) no: esa es la tarjeta de la notificación, con
//     Contestar y Rechazar.
//   - Si hay varias, manda la activa; si no, la que se está marcando; si no,
//     la que está en espera.
//   - Nombre: el contacto que conoce BlueFerry. Si no lo conoce (sin
//     contactos sincronizados solo trae el número), el que puso el iPhone en
//     su propio aviso de la llamada ("Phone · Caller"). Si tampoco, el número.
//   - El tiempo cuenta desde que la llamada pasa a activa, no desde que sonó.
//   - Silenciar es silenciar el micrófono de la PC: es el que oye la llamada.

pragma Singleton

import QtQuick
import Quickshell
import qs.data.phone
import qs.domain.audio

Singleton {
    id: root

    readonly property var calls: CallsRepository.calls

    readonly property var current: root.calls.find(c => c.state === "active")
        ?? root.calls.find(c => c.state === "dialing" || c.state === "alerting")
        ?? root.calls.find(c => c.state === "held")
        ?? (root.answering ? root.calls.find(c => c.state === "incoming") ?? null : null)

    // Recién tocado Contestar: la llamada tarda un instante en pasar a activa.
    // Mientras, ya cuenta como en curso ("Conectando…"), para que la isla
    // pase de la tarjeta que suena a la llamada sin cerrarse en medio.
    property bool answering: false

    function expectAnswer(): void {
        root.answering = true;
        answerGrace.restart();
    }

    Timer {
        id: answerGrace
        interval: 6000
        onTriggered: root.answering = false
    }

    readonly property bool ongoing: root.current !== null
    readonly property string currentId: root.current ? root.current.id : ""

    // ── quién llama ───────────────────────────────────────────────
    //
    // Lo que dijo el iPhone en su aviso: { name, label ("mobile"), at }. Lo
    // apunta Notifications al ver ese aviso, aunque no lo enseñe.
    property var hint: null

    // Nombre que se le quedó a cada llamada (id → nombre), para que no cambie
    // a media llamada cuando el aviso del iPhone ya se fue.
    property var names: ({})

    function noteCaller(name, label): void {
        const who = String(name || "").trim();
        if (who.length === 0 || root.looksLikeNumber(who))
            return;

        root.hint = { name: who, label: String(label || "").trim(), at: Date.now() };

        // Una llamada que ya está sonando o en curso sin nombre lo toma ahora.
        root.adopt();
    }

    function looksLikeNumber(text): bool {
        return /^[+()\d\s.\-]{5,}$/.test(String(text || "").trim());
    }

    // El aviso sirve un minuto y medio: lo que tarda en sonar una llamada.
    function freshHint() {
        if (!root.hint || Date.now() - root.hint.at > 90000)
            return null;
        return root.hint;
    }

    // ¿Qué nombre le toca a una llamada que BlueFerry solo conoce por número?
    // Lo usa también la tarjeta de la llamada que suena.
    function hintFor(peer) {
        if (!root.looksLikeNumber(peer))
            return null;
        return root.freshHint();
    }

    function adopt(): void {
        const hint = root.freshHint();
        if (!hint)
            return;

        let changed = false;
        const names = Object.assign({}, root.names);

        for (let i = 0; i < root.calls.length; ++i) {
            const call = root.calls[i];
            if (!call.name && !names[call.id]) {
                names[call.id] = hint.name;
                changed = true;
            }
        }

        if (changed)
            root.names = names;
    }

    function nameOf(call): string {
        if (!call)
            return "";
        return call.name || root.names[call.id] || call.network || call.number || "Desconocido";
    }

    readonly property string name: root.nameOf(root.current)

    // ── el tiempo ─────────────────────────────────────────────────
    //
    // id → cuándo se vio activa por primera vez (ms).
    property var since: ({})

    onCallsChanged: {
        const since = {};
        const names = {};
        const now = Date.now();

        for (let i = 0; i < root.calls.length; ++i) {
            const call = root.calls[i];
            if (root.since[call.id])
                since[call.id] = root.since[call.id];
            else if (call.state === "active")
                since[call.id] = now;
            if (root.names[call.id])
                names[call.id] = root.names[call.id];
        }

        // Lo de las llamadas que ya terminaron se olvida.
        root.since = since;
        root.names = names;
        root.adopt();
    }

    // "0:15", "12:03", "1:02:45" — o lo que está pasando si aún no hay tiempo.
    function clockAt(now): string {
        const call = root.current;
        if (!call)
            return "";
        if (call.state === "incoming" || call.state === "waiting")
            return "Conectando…";
        if (call.state === "dialing" || call.state === "alerting")
            return "Llamando…";
        if (call.state === "held")
            return "En espera";

        const start = root.since[call.id] || now;
        const total = Math.max(0, Math.floor((now - start) / 1000));
        const h = Math.floor(total / 3600);
        const m = Math.floor((total % 3600) / 60);
        const s = total % 60;
        const ss = (s < 10 ? "0" : "") + s;

        if (h > 0)
            return h + ":" + (m < 10 ? "0" : "") + m + ":" + ss;
        return m + ":" + ss;
    }

    // ── los botones ───────────────────────────────────────────────

    function hangUp(): void {
        if (root.current)
            CallsRepository.hangup(root.current.id);
    }

    readonly property bool muted: Microphone.muted

    function toggleMute(): void {
        Microphone.toggleMute();
    }

    // El "altavoz" de la PC: pasa a la siguiente salida de audio (bocinas,
    // audífonos, pantalla…) y dice cuál quedó.
    readonly property var output: Audio.outputs.find(o => o.selected) ?? null

    function nextOutput(): void {
        const list = Audio.outputs;
        if (list.length < 2)
            return;

        const at = list.findIndex(o => o.selected);
        Audio.selectOutput(list[(at + 1) % list.length].id);
    }
}
