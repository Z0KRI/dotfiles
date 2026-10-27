// CASO DE USO: el portapapeles en Spotlight, el equivalente de Win + V.
// Reglas:
//   - Sin texto: todo el historial, lo más nuevo arriba.
//   - Con texto: cada palabra tiene que estar en la vista previa.
//   - Enter PEGA en la ventana donde estabas (se puede cambiar en Ajustes
//     para que solo copie). Ctrl + Enter siempre solo copia.
//   - Las terminales pegan con Ctrl + Shift + V; en ellas Ctrl + V no pega,
//     manda un ^V literal. Se reconocen por su clase de Hyprland.

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

    function find(query, limit) {
        const words = String(query ?? "").trim().toLowerCase().split(/\s+/).filter(word => word.length > 0);

        return ClipboardRepository.entries
            .filter(entry => {
                const text = entry.preview.toLowerCase();
                return words.every(word => text.indexOf(word) >= 0);
            })
            .slice(0, limit);
    }

    // `copyOnly`: Ctrl + Enter.
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
}
