// REPOSITORIO: el historial del portapapeles, que guarda cliphist. El que lo
// llena es el vigilante que arranca con Hyprland (hyprland.lua):
//     wl-paste --watch cliphist store
//
// `cliphist list` devuelve una línea por entrada, "ID<TAB>vista previa", de la
// más nueva a la más vieja. Esa línea completa es justo lo que esperan
// `cliphist decode` y `cliphist delete`, así que se guarda tal cual en `line`
// y nunca hay que reconstruirla.
//
// Qué se muestra y cómo se filtra lo decide domain/clipboard/SearchClipboard;
// con qué atajo se pega (Ctrl+V o Ctrl+Shift+V), también.
//
// Las imágenes: cliphist solo da su descripción ("[[ binary data … png ]]").
// Para la miniatura del panel se decodifican a archivos en
// $XDG_RUNTIME_DIR/z0-clipboard/ (un tmpfs que se borra al cerrar sesión),
// una vez cada una, y `thumbs` dice dónde quedó cada una.

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // [{ id: "42", preview: "texto…", line: "42\ttexto…" }]
    property var entries: []

    // id → "file:///…/42.png", solo de las imágenes ya decodificadas.
    property var thumbs: ({})

    // Cuántas miniaturas se preparan, de las más nuevas: más atrás casi
    // nunca se ven y cada una es un archivo.
    readonly property int thumbLimit: 40
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

    // Todo el historial, y las miniaturas con él.
    function wipe(): void {
        root.entries = [];
        root.thumbs = ({});

        Quickshell.execDetached(["sh", "-c",
            'cliphist wipe; rm -rf "${XDG_RUNTIME_DIR:-/tmp}/z0-clipboard"']);
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
                return;
            }

            root.makeThumbs();
        }
    }

    // ── miniaturas ────────────────────────────────────────────────
    //
    // Un solo proceso para todas: recibe las líneas de las imágenes y por
    // cada una escribe su archivo si todavía no existe. Imprime "id<TAB>ruta"
    // de las que quedaron, y de eso sale `thumbs`. La extensión es la que
    // dice cliphist (png, jpeg…), para que Qt sepa leerla.
    function makeThumbs(): void {
        const images = root.entries
            .filter(entry => /^\[\[ binary data .+ [a-z0-9]+ \d+x\d+ \]\]$/i.test(entry.preview))
            .slice(0, root.thumbLimit);

        if (images.length === 0 || thumbnailer.running)
            return;

        thumbnailer.command = ["sh", "-c",
            'dir="${XDG_RUNTIME_DIR:-/tmp}/z0-clipboard"\n'
            + 'mkdir -p "$dir" || exit 0\n'
            + 'for line in "$@"; do\n'
            + '  id="${line%%\t*}"\n'
            + '  ext=$(printf "%s" "$line" | sed -E "s/.* ([a-z0-9]+) [0-9]+x[0-9]+ \\]\\]$/\\1/I")\n'
            + '  file="$dir/$id.$ext"\n'
            + '  [ -s "$file" ] || printf "%s\\n" "$line" | cliphist decode > "$file" 2>/dev/null\n'
            + '  if [ -s "$file" ]; then printf "%s\\t%s\\n" "$id" "$file"; else rm -f "$file"; fi\n'
            + 'done',
            "sh"].concat(images.map(entry => entry.line));
        thumbnailer.running = true;
    }

    Process {
        id: thumbnailer

        stdout: StdioCollector {
            id: made
        }

        onExited: (exitCode, exitStatus) => {
            const next = {};
            String(made.text || "").split("\n").forEach(row => {
                const tab = row.indexOf("\t");
                if (tab > 0)
                    next[row.slice(0, tab)] = "file://" + row.slice(tab + 1);
            });
            root.thumbs = next;
        }
    }
}
