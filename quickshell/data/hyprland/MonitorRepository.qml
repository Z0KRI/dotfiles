pragma Singleton

// REPOSITORIO: el único que lee y cambia la configuración de los monitores.
// Tres cosas, y ninguna decide nada (eso es de domain/desktop/Displays):
//
//   1. LEER  `hyprctl -j monitors all`: todos los monitores, también los
//      apagados, con sus modos disponibles. Lo de Quickshell (Hyprland.monitors)
//      no sirve aquí: no trae los apagados ni la lista de modos.
//   2. APLICAR `hyprctl eval 'hl.monitor({...})'`. Con la config en Lua,
//      `hyprctl keyword monitor` ya no existe; eval corre Lua dentro de
//      Hyprland, y hl.monitor() de un monitor que ya tiene regla solo cambia
//      los campos que le pasas, y lo aplica al momento.
//   3. GUARDAR en hypr/hosts/displays.lua. Lo de eval vive en memoria: el
//      siguiente `hyprctl reload` lo borra. hosts/init.lua carga ese archivo
//      después del perfil de la máquina, así que lo guardado sobrevive.
//
// Lo guardado también va a un JSON (displays.json, en el estado de
// Quickshell). El .lua es lo que lee Hyprland; el JSON es de donde se vuelve a
// escribir. Así un monitor desconectado no pierde su regla: el proyector de la
// oficina conserva la suya aunque hoy no esté.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    // Lo que devolvió hyprctl, tal cual (con dos arreglos convertidos).
    property var monitors: []
    property bool loaded: false

    // El texto del último error de Hyprland, o "".
    property string lastError: ""

    signal applied()

    readonly property string hyprDir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/hypr"
    readonly property string luaPath: root.hyprDir + "/hosts/displays.lua"

    // ── leer ─────────────────────────────────────────────────────
    function refresh(): void {
        if (reader.running)
            reader.rerun = true;
        else
            reader.running = true;
    }

    // ── aplicar ──────────────────────────────────────────────────
    //
    // rules: [{ output, mode, position, scale, transform, vrr, disabled, mirror }]
    // Van todas en UN solo eval: si se mueven dos monitores a la vez, Hyprland
    // los reacomoda juntos y no pasa por un estado intermedio encimado.
    function apply(rules): void {
        if (!rules || rules.length === 0)
            return;

        // Optimista: la UI ve el cambio ya. La lectura de verdad llega en
        // cuanto Hyprland termine de cambiar de modo.
        root.monitors = root.monitors.map(monitor => {
            const rule = rules.find(r => r.output === monitor.name);
            return rule ? root.merged(monitor, rule) : monitor;
        });

        root.queue = root.queue.concat([rules.map(root.toLua).join("\n")]);
        root.next();
    }

    // ── guardar ──────────────────────────────────────────────────
    function save(rules): void {
        const next = Object.assign({}, store.rules);
        for (const rule of rules)
            next[rule.output] = rule;
        store.rules = next;

        luaFile.setText(root.luaText(next));
    }

    // Olvida todo lo guardado y vuelve a lo del archivo de la máquina.
    function reset(): void {
        store.rules = ({});
        luaFile.setText(root.luaText({}));
        Quickshell.execDetached(["hyprctl", "reload"]);
        refreshLater.restart();
    }

    function savedRule(output) {
        return store.rules[output] ?? null;
    }

    // ── internos ─────────────────────────────────────────────────
    property var queue: []

    function next(): void {
        if (writer.running || root.queue.length === 0)
            return;

        writer.code = root.queue[0];
        root.queue = root.queue.slice(1);
        writer.running = true;
    }

    // Una regla como código Lua. Los textos van entre comillas y con las
    // comillas de adentro escapadas: un nombre raro no rompe el eval.
    function toLua(rule): string {
        const quote = value => '"' + String(value).replace(/\\/g, "\\\\").replace(/"/g, '\\"') + '"';
        const fields = ["output = " + quote(rule.output)];

        if (rule.disabled) {
            fields.push("disabled = true");
        } else {
            fields.push("disabled = false");
            fields.push("mode = " + quote(rule.mode));
            fields.push("position = " + quote(rule.position));
            fields.push("scale = " + quote(rule.scale));
            fields.push("transform = " + (rule.transform | 0));
            fields.push("vrr = " + (rule.vrr | 0));
            fields.push("mirror = " + quote(rule.mirror || ""));
        }

        return "hl.monitor({ " + fields.join(", ") + " })";
    }

    function luaText(rules): string {
        const names = Object.keys(rules).sort();
        const header = [
            "-- hypr/hosts/displays.lua",
            "--",
            "-- Lo escribe tu shell: Ajustes › Pantallas. No lo edites a mano, se",
            "-- reescribe cada vez que guardas un cambio ahí.",
            "--",
            "-- hosts/init.lua lo carga DESPUÉS del archivo de esta máquina, y",
            "-- hl.monitor() de un monitor que ya tiene regla solo cambia los campos",
            "-- que trae. Para volver a lo de tu hosts/<equipo>.lua: Ajustes ›",
            "-- Pantallas › Restablecer, o borra este archivo.",
            ""
        ];
        return header.concat(names.map(name => root.toLua(rules[name]))).join("\n") + "\n";
    }

    // Lo que se ve de un monitor después de aplicarle una regla.
    function merged(monitor: var, rule: var): var {
        const out = Object.assign({}, monitor, { disabled: !!rule.disabled });
        if (rule.disabled)
            return out;

        const mode = /^(\d+)x(\d+)@([\d.]+)/.exec(rule.mode);
        if (mode) {
            out.width = parseInt(mode[1]);
            out.height = parseInt(mode[2]);
            out.refreshRate = parseFloat(mode[3]);
        }

        const position = /^(-?\d+)x(-?\d+)$/.exec(rule.position);
        if (position) {
            out.x = parseInt(position[1]);
            out.y = parseInt(position[2]);
        }

        if (!isNaN(parseFloat(rule.scale)))
            out.scale = parseFloat(rule.scale);

        out.transform = rule.transform | 0;
        out.mirrorName = rule.mirror || "";
        return out;
    }

    Process {
        id: reader

        property bool rerun: false

        command: ["hyprctl", "-j", "monitors", "all"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const list = JSON.parse(this.text);
                    // `mirrorOf` viene como id: se pasa a nombre, que es lo
                    // que entiende hl.monitor().
                    root.monitors = list.map(monitor => Object.assign({}, monitor, {
                        mirrorName: monitor.mirrorOf === "none"
                            ? ""
                            : (list.find(other => String(other.id) === String(monitor.mirrorOf))?.name ?? "")
                    }));
                    root.loaded = true;
                } catch (error) {
                    root.lastError = "No pude leer la lista de monitores de Hyprland.";
                }
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
        id: writer

        property string code: ""

        command: ["hyprctl", "eval", writer.code]

        // eval contesta "ok" o el error de Lua/de hl.monitor().
        stdout: StdioCollector {
            onStreamFinished: {
                const answer = this.text.trim();
                root.lastError = answer === "ok" || answer === "" ? "" : answer;
            }
        }

        onExited: (exitCode, exitStatus) => {
            root.applied();
            refreshLater.restart();
            root.next();
        }
    }

    // Cambiar de modo tarda: Hyprland apaga y prende la salida. Se lee de
    // nuevo un momento después para tener los valores reales.
    Timer {
        id: refreshLater
        interval: 700
        onTriggered: root.refresh()
    }

    // Conectar o desconectar un monitor, o recargar la config: hay que releer.
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (["monitoradded", "monitoraddedv2", "monitorremoved", "monitorremovedv2",
                 "configreloaded"].indexOf(event.name) >= 0)
                refreshLater.restart();
        }
    }

    FileView {
        id: luaFile
        path: root.luaPath
        blockLoading: false
        printErrors: false
    }

    FileView {
        path: Quickshell.statePath("displays.json")
        watchChanges: true

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: store

            // salida → la regla guardada, ej. "HDMI-A-1": { mode, position, ... }
            property var rules: ({})
        }
    }

    Component.onCompleted: root.refresh()
}
