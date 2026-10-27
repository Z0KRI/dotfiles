// REPOSITORIO: el historial del portapapeles, que guarda cliphist. El que lo
// llena es el vigilante que arranca con Hyprland (hyprland.lua):
//     wl-paste --watch cliphist store
//
// `cliphist list` devuelve una línea por entrada, "ID<TAB>vista previa", de la
// más nueva a la más vieja. Esa línea completa es justo lo que esperan
// `cliphist decode` y `cliphist delete`, así que se guarda tal cual en `line`
// y nunca hay que reconstruirla.
//
// Qué se muestra y cómo se filtra lo decide domain/launcher/SearchClipboard;
// con qué atajo se pega (Ctrl+V o Ctrl+Shift+V), también.

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // [{ id: "42", preview: "texto…", line: "42\ttexto…" }]
    property var entries: []
    property bool loaded: false
    // false si cliphist no está instalado.
    property bool available: true

    function refresh(): void {
        if (lister.running)
            lister.rerun = true;
        else
            lister.running = true;
    }

    // Lo deja en el portapapeles, nada más.
    function copy(line): void {
        if (!line)
            return;

        Quickshell.execDetached(["sh", "-c",
            'printf "%s\\n" "$1" | cliphist decode | wl-copy',
            "sh", line]);
    }

    // Lo copia y lo pega en la ventana activa con `mods` + V.
    //
    // El pegado tiene que esperar a que Spotlight se cierre: mientras está
    // abierto, el teclado es suyo. Quien llama cierra Spotlight y esto espera
    // un poco antes de mandar la tecla. Además va con window = 'activewindow',
    // así Hyprland manda el atajo a esa ventana aunque el foco aún no haya
    // vuelto del todo.
    //
    // Con la config en Lua, `hyprctl dispatch` recibe la llamada de Lua
    // entera (así lo prueban los tests del propio Hyprland).
    function paste(line, mods): void {
        if (!line)
            return;

        Quickshell.execDetached(["sh", "-c",
            'printf "%s\\n" "$1" | cliphist decode | wl-copy >/dev/null 2>&1\n'
            + 'sleep 0.15\n'
            + "hyprctl dispatch \"hl.dsp.send_shortcut({ mods = '$2', key = 'V', window = 'activewindow' })\" >/dev/null",
            "sh", line, mods || "CTRL"]);
    }

    function remove(line): void {
        if (!line)
            return;

        // Se quita de la lista ya, sin esperar a cliphist: si no, la fila
        // tardaría un instante en desaparecer.
        root.entries = root.entries.filter(entry => entry.line !== line);

        Quickshell.execDetached(["sh", "-c",
            'printf "%s\\n" "$1" | cliphist delete', "sh", line]);
    }

    function parse(text) {
        return String(text || "").split("\n")
            .filter(line => line.length > 0)
            .map(line => {
                const tab = line.indexOf("\t");
                return {
                    id: tab >= 0 ? line.slice(0, tab) : line,
                    preview: tab >= 0 ? line.slice(tab + 1) : "",
                    line: line
                };
            });
    }

    Process {
        id: lister

        property bool rerun: false

        command: ["sh", "-c", "command -v cliphist >/dev/null 2>&1 || exit 127; cliphist list"]

        stdout: StdioCollector {
            id: listed
        }

        onExited: (exitCode, exitStatus) => {
            root.available = exitCode !== 127;
            root.entries = root.available ? root.parse(listed.text) : [];
            root.loaded = true;

            if (lister.rerun) {
                lister.rerun = false;
                lister.running = true;
            }
        }
    }
}
