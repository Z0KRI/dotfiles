// REPOSITORIO: herramientas de captura.
//   - Recorte: slurp (eliges la zona) + grim (la captura) + wl-copy.
//   - Selector de color: hyprpicker.

pragma Singleton

import Quickshell

Singleton {
    // Guarda en <Imágenes>/<folder>/<name> y copia al portapapeles.
    // Si cancelas la selección con Esc, no pasa nada.
    function screenshotRegion(folder, name): void {
        Quickshell.execDetached(["sh", "-c",
            'dir="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/$1"; '
            + 'mkdir -p "$dir"; '
            + 'region="$(slurp)" || exit 0; '
            + 'grim -g "$region" "$dir/$2" && wl-copy < "$dir/$2"',
            "sh", folder, name]);
    }

    function pickColor(): void {
        Quickshell.execDetached(["hyprpicker", "--autocopy"]);
    }
}