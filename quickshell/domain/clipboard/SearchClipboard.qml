// CASO DE USO: el historial del portapapeles, el equivalente de Win + V.
// Reglas:
//   - Sin texto: todo el historial, lo más nuevo arriba.
//   - Con texto: cada palabra tiene que estar en la vista previa.
//   - Enter PEGA en la ventana donde estabas (se puede cambiar en Ajustes
//     para que solo copie). Ctrl + Enter siempre solo copia.
//   - Las terminales pegan con Ctrl + Shift + V; en ellas Ctrl + V no pega,
//     manda un ^V literal. Se reconocen por su clase de Hyprland.
//   - Cada entrada dice QUÉ es (imagen, enlace, ruta, comando, código o
//     texto) para que la lista se lea de un vistazo. Lo adivina por la forma
//     del texto: cliphist no guarda de dónde vino ni cuándo.

pragma Singleton

import Quickshell
import qs.data.clipboard
import qs.data.hyprland
import qs.data.system

Singleton {
    id: root

    readonly property bool available: ClipboardRepository.available
    readonly property bool loaded: ClipboardRepository.loaded
    readonly property bool empty: ClipboardRepository.entries.length === 0

    readonly property bool pastes: PreferencesRepository.launcherPaste

    function setPastes(on): void {
        PreferencesRepository.launcherPaste = on;
    }

    // Las clases de terminal (hyprctl activewindow -j | grep class).
    // Va dentro de una función y no en una propiedad: una propiedad `var`
    // convierte la expresión regular a un tipo de Qt y pierde test().
    function isTerminal(appId) {
        return /^(com\.mitchellh\.ghostty|dev\.warp\.Warp|kitty|Alacritty|foot|org\.wezfurlong\.wezterm)$/.test(appId);
    }

    function refresh(): void {
        ClipboardRepository.refresh();
    }

    // Las entradas que coinciden, ya descritas (ver describe()).
    function find(query, limit) {
        const words = String(query ?? "").trim().toLowerCase().split(/\s+/).filter(word => word.length > 0);

        return ClipboardRepository.entries
            .filter(entry => {
                const text = entry.preview.toLowerCase();
                return words.every(word => text.indexOf(word) >= 0);
            })
            .slice(0, limit)
            .map(root.describe);
    }

    // ── qué es cada entrada ───────────────────────────────────────
    //
    // {
    //   kind:    "image" | "link" | "path" | "command" | "code" | "text"
    //   key:     el id de cliphist (único)
    //   text:    lo que se lee: la vista previa en una línea, o "Imagen PNG"
    //   label:   el tipo en palabras ("Código", "Imagen PNG · 800 × 600")
    //   mono:    true si se lee mejor en monoespaciada (código, rutas…)
    //   thumb:   la miniatura de una imagen ("" mientras no exista)
    //   target:  la entrada de cliphist, para pegarla o borrarla
    // }
    //
    // Las expresiones van aquí adentro y no en propiedades: una propiedad
    // `var` convierte la expresión regular a un tipo de Qt y pierde exec().
    function describe(entry) {
        const preview = String(entry.preview || "");

        // cliphist describe las imágenes así: "[[ binary data 23 KiB png 800x600 ]]".
        const binary = /^\[\[ binary data (.+) ([a-z0-9]+) (\d+)x(\d+) \]\]$/i.exec(preview);
        if (binary) {
            return {
                kind: "image",
                key: entry.id,
                text: "Imagen " + binary[2].toUpperCase(),
                label: binary[3] + " × " + binary[4] + " · " + binary[1],
                mono: false,
                thumb: ClipboardRepository.thumbs[entry.id] ?? "",
                target: entry
            };
        }

        const text = preview.replace(/\s+/g, " ").trim() || " ";
        const kind = root.kindOf(text);

        return {
            kind: kind,
            key: entry.id,
            text: text,
            label: root.labels[kind],
            mono: kind === "path" || kind === "command" || kind === "code",
            thumb: "",
            target: entry
        };
    }

    readonly property var labels: ({
        link: "Enlace",
        path: "Ruta",
        command: "Comando",
        code: "Código",
        text: "Texto"
    })

    // Adivinar es adivinar: el orden importa. Lo más fácil de reconocer va
    // primero (un enlace no tiene espacios y empieza con su esquema).
    function kindOf(text) {
        if (/^(https?|ftp):\/\/\S+$/i.test(text))
            return "link";

        // ~/algo, /algo o file:///algo, sin espacios.
        if (/^(~\/|\/|file:\/\/)\S*$/.test(text))
            return "path";

        // Una palabra de comando seguida de una opción (-x, --algo), una
        // tubería, o sudo al principio: "qs -p ~/x", "ls | grep", "sudo …".
        if (/^(sudo\s+)?[a-z][\w.+-]*\s+(.*\s)?(--?[\w-]+|\|)(\s|$)/.test(text) || /^sudo\s/.test(text))
            return "command";

        // Llaves, punto y coma, flechas, asignaciones o llamadas: código.
        if (/[{};]|=>|\w\(.*\)|^\s*(const|let|var|function|import|def|class|return)\b/.test(text))
            return "code";

        return "text";
    }

    // ── elegir ────────────────────────────────────────────────────

    // `copyOnly`: Ctrl + Enter. Recibe la entrada de cliphist (`target`).
    function choose(entry, copyOnly): void {
        if (!entry)
            return;

        if (copyOnly || !root.pastes) {
            ClipboardRepository.copy(entry.line);
            return;
        }

        const mods = root.isTerminal(HyprlandRepository.activeAppId) ? "CTRL SHIFT" : "CTRL";
        ClipboardRepository.paste(entry.line, mods);
    }

    function remove(entry): void {
        if (entry)
            ClipboardRepository.remove(entry.line);
    }

    // Todo el historial. Sin vuelta atrás: quien llama pide confirmación.
    function clear(): void {
        ClipboardRepository.wipe();
    }
}
