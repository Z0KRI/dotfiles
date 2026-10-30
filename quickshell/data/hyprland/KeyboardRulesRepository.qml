pragma Singleton

// REPOSITORIO: las reglas de un teclado en particular (hl.device): su
// distribución y opciones de xkb propias, para que cada teclado (el Apple, el
// Dell, el ROG…) tenga lo suyo sin cambiar a los demás. Mismo patrón que
// MonitorRepository:
//
//   1. LEER  `hyprctl -j devices`: los teclados que ve Hyprland, con el nombre
//      que usan las reglas ("magic-keyboard") y su distribución. Se vuelve a
//      leer cuando el dominio lo pide (al conectar o desconectar uno), al
//      recargar la config y cuando Hyprland configura un teclado.
//   2. APLICAR `hyprctl eval '…hl.device({...})'`: vale al momento (Hyprland
//      vuelve a configurar los teclados al recibirlo).
//   3. GUARDAR en hypr/hosts/keyboard.lua, que hosts/init.lua carga después
//      del perfil de la máquina, y en keyboards.json (estado de Quickshell),
//      de donde se vuelve a escribir el .lua. Así la regla de un teclado
//      apagado no se pierde.
//
// Una regla: { layout, variant, options }, cada parte opcional.
//   layout/variant  sin ellas, la del equipo (hosts/<equipo>.lua)
//   options         opciones de xkb SOLO de este teclado, que se suman a las
//                   del equipo (ej. "altwin:swap_lalt_lwin": ⌘ y ⌥ cambiadas)
//
// Lo que una regla no fija se toma del equipo AL CARGAR (hl.get_config), no
// se copia al archivo: si cambias tu hosts/<equipo>.lua, las reglas lo
// siguen. Y quitar una regla se hace en caliente igual: se le vuelve a dar a
// ese teclado lo del equipo, sin recargar toda la config.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    // [{ name, layout, variant, main }]
    property var keyboards: []

    // { "magic-keyboard": { layout: "es", variant: "mac", options: "altwin:swap_lalt_lwin" } }
    readonly property var rules: store.rules

    property string lastError: ""

    readonly property string hyprDir: (Quickshell.env("XDG_CONFIG_HOME") || (Quickshell.env("HOME") + "/.config")) + "/hypr"
    readonly property string luaPath: root.hyprDir + "/hosts/keyboard.lua"

    function refresh(): void {
        if (reader.running)
            reader.rerun = true;
        else
            reader.running = true;
    }

    // Cambia una parte de la regla de estos nombres y deja igual lo demás.
    //   { layout: "es", variant: "mac" }   fija la distribución
    //   { layout: "" }                     vuelve a la del equipo
    //   { options: "altwin:…" } / { options: "" }
    function update(names, patch): void {
        if (!names || names.length === 0)
            return;

        const next = Object.assign({}, store.rules);
        for (const name of names) {
            const rule = Object.assign({}, next[name] ?? {});

            if (patch.layout !== undefined) {
                if (patch.layout === "") {
                    delete rule.layout;
                    delete rule.variant;
                } else {
                    rule.layout = patch.layout;
                    rule.variant = patch.variant || "";
                }
            }
            if (patch.options !== undefined) {
                if (patch.options === "")
                    delete rule.options;
                else
                    rule.options = patch.options;
            }

            if (rule.layout === undefined && rule.options === undefined)
                delete next[name];
            else
                next[name] = rule;
        }

        store.rules = next;
        luaFile.setText(root.luaText(next));

        // Sin regla, `toLua` le da lo del equipo: así se quita en caliente.
        root.evaluate("do\n" + root.prelude + "\n"
                      + names.map(name => root.toLua(name, next[name] ?? {})).join("\n") + "\nend");
    }

    // ── internos ─────────────────────────────────────────────────

    // Si eliges otra mientras la anterior todavía se aplica, se junta con lo
    // pendiente y va en el siguiente eval. Juntar y no reemplazar: pueden ser
    // teclados distintos (el Dell y el ROG), y los dos tienen que llegar.
    // Si es el mismo teclado dos veces, gana la última.
    function evaluate(code): void {
        if (writer.running) {
            writer.pending = writer.pending !== "" ? writer.pending + "\n" + code : code;
            return;
        }
        writer.code = code;
        writer.running = true;
    }

    // Los textos van entre comillas y con las de adentro escapadas: un
    // nombre raro no rompe el eval.
    function quote(value): string {
        return '"' + String(value).replace(/\\/g, "\\\\").replace(/"/g, '\\"').replace(/\n/g, " ") + '"';
    }

    // Lo del equipo se lee de la config ya cargada (la de hosts/<equipo>.lua).
    readonly property string prelude: [
        "local function base(key)",
        "    return hl.get_config(\"input.\" .. key) or \"\"",
        "end",
        "",
        "-- Las opciones del equipo más las de este teclado.",
        "local function options(extra)",
        "    local current = base(\"kb_options\")",
        "    if current == \"\" then return extra end",
        "    if extra == \"\" then return current end",
        "    return current .. \",\" .. extra",
        "end"
    ].join("\n")

    function toLua(name, rule): string {
        const layout = rule.layout !== undefined
            ? "kb_layout = " + root.quote(rule.layout) + ", kb_variant = " + root.quote(rule.variant || "")
            : "kb_layout = base(\"kb_layout\"), kb_variant = base(\"kb_variant\")";
        return "hl.device({ name = " + root.quote(name) + ", " + layout
               + ", kb_options = options(" + root.quote(rule.options || "") + ") })";
    }

    function luaText(rules): string {
        const names = Object.keys(rules).sort();
        const header = [
            "-- hypr/hosts/keyboard.lua",
            "--",
            "-- Lo escribe tu shell: Ajustes › Teclado. No lo edites a mano: se",
            "-- reescribe cada vez que cambias algo ahí.",
            "--",
            "-- Una regla por teclado, por su nombre en `hyprctl devices`. Los demás",
            "-- siguen con lo de hosts/<equipo>.lua, y lo que una regla no fija también",
            "-- sale de ahí (se lee al cargar). Es de esta máquina: el Dell de la",
            "-- oficina y el ROG de casa tienen cada uno lo suyo. Para quitarlo todo:",
            "-- borra este archivo.",
            "",
            root.prelude,
            ""
        ];
        return header.concat(names.map(name => root.toLua(name, rules[name]))).join("\n") + "\n";
    }

    Process {
        id: reader

        property bool rerun: false

        command: ["hyprctl", "-j", "devices"]

        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const devices = JSON.parse(this.text);
                    root.keyboards = (devices.keyboards || []).map(keyboard => ({
                        name: keyboard.name,
                        layout: keyboard.layout,
                        variant: keyboard.variant,
                        main: !!keyboard.main
                    }));
                } catch (error) {
                    root.lastError = "No pude leer los teclados de Hyprland.";
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
        property string pending: ""

        command: ["hyprctl", "eval", writer.code]

        stdout: StdioCollector {
            onStreamFinished: {
                const answer = this.text.trim();
                root.lastError = answer === "ok" || answer === "" ? "" : answer;
            }
        }

        onExited: (exitCode, exitStatus) => {
            if (writer.pending !== "") {
                writer.code = writer.pending;
                writer.pending = "";
                writer.running = true;
            }
            refreshLater.restart();
        }
    }

    Timer {
        id: refreshLater
        interval: 500
        onTriggered: root.refresh()
    }

    // "activelayout" también llega al configurar un teclado recién conectado:
    // sirve de respaldo si udevadm no está (ver InputRepository).
    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (event.name === "configreloaded" || event.name === "activelayout")
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
        path: Quickshell.statePath("keyboards.json")
        watchChanges: true

        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()

        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: store
            property var rules: ({})
        }
    }
}
