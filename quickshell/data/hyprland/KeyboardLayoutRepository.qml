pragma Singleton

// REPOSITORIO: la distribución de un teclado en particular (hl.device), para
// que cada teclado (el Apple, el Dell, el ROG…) pueda tener la suya sin
// cambiar la de los demás. Mismo patrón que MonitorRepository:
//
//   1. LEER  `hyprctl -j devices`: los teclados que ve Hyprland, con el nombre
//      que usan las reglas ("magic-keyboard") y su distribución. Se vuelve a
//      leer al conectar uno: Hyprland avisa con "activelayout" al configurar
//      un teclado nuevo (y también al cambiar de distribución con el atajo;
//      leer de más no cuesta nada).
//   2. APLICAR `hyprctl eval 'hl.device({...})'`: vale al momento (Hyprland
//      recarga los dispositivos al recibirlo).
//   3. GUARDAR en hypr/hosts/keyboard.lua, que hosts/init.lua carga después
//      del perfil de la máquina, y en keyboards.json (estado de Quickshell),
//      de donde se vuelve a escribir el .lua. Así la regla de un teclado
//      apagado no se pierde.
//
// Quitar una regla es lo único que no se puede en caliente: Hyprland no tiene
// cómo "olvidar" un hl.device. Se reescribe el .lua sin ella y se recarga la
// config (`hyprctl reload`), que es lo mismo que pasa al guardar un archivo.

import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Singleton {
    id: root

    // [{ name, layout, variant, main }]
    property var keyboards: []

    // { "magic-keyboard": { layout: "es", variant: "mac" } }
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

    function setRule(names, layout, variant): void {
        if (!names || names.length === 0)
            return;

        const next = Object.assign({}, store.rules);
        for (const name of names)
            next[name] = { layout: layout, variant: variant || "" };
        store.rules = next;
        luaFile.setText(root.luaText(next));

        root.evaluate(names.map(name => root.toLua(name, next[name])).join("\n"));
    }

    function clearRule(names): void {
        const next = Object.assign({}, store.rules);
        let changed = false;
        for (const name of names) {
            if (next[name]) {
                delete next[name];
                changed = true;
            }
        }
        if (!changed)
            return;

        store.rules = next;
        luaFile.setText(root.luaText(next));
        Quickshell.execDetached(["hyprctl", "reload"]);
        refreshLater.restart();
    }

    // ── internos ─────────────────────────────────────────────────

    // Si eliges otra mientras la anterior todavía se aplica, se junta con lo
    // pendiente y va en el siguiente eval. Juntar y no reemplazar: pueden ser
    // teclados distintos (el Dell y el ROG), y los dos tienen que llegar.
    // Si es el mismo teclado dos veces, gana la última línea.
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

    function toLua(name, rule): string {
        return "hl.device({ name = " + root.quote(name)
               + ", kb_layout = " + root.quote(rule.layout)
               + ", kb_variant = " + root.quote(rule.variant || "") + " })";
    }

    function luaText(rules): string {
        const names = Object.keys(rules).sort();
        const header = [
            "-- hypr/hosts/keyboard.lua",
            "--",
            "-- Lo escribe tu shell: Ajustes › Teclado › Distribución. No lo edites a",
            "-- mano: se reescribe cada vez que eliges una ahí.",
            "--",
            "-- Una regla por teclado, por su nombre en `hyprctl devices`. Los demás",
            "-- siguen con el kb_layout de hosts/<equipo>.lua. Es de esta máquina: el",
            "-- Dell de la oficina y el ROG de casa tienen cada uno la suya. Para volver",
            "-- a la del equipo: Ajustes › Teclado › La del equipo, o borra este archivo.",
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
