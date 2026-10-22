// REPOSITORIO: herramientas de captura.
//   - Recorte: slurp (eliges la zona) + grim (la captura) + wl-copy.
//   - Pantalla: grim -o <monitor> + wl-copy.
//   - Selector de color: hyprpicker.
//
// Las dos capturas comparten el mismo final (carpeta, archivo, portapapeles):
// por eso lo arma una sola función y solo cambia cómo se captura.

pragma Singleton

import Quickshell

Singleton {
    id: root

    // Guarda en <Imágenes>/<folder>/<name> y copia al portapapeles.
    // Si cancelas la selección con Esc, no pasa nada.
    function screenshotRegion(folder, name): void {
        root._capture('region="$(slurp)" || exit 0; grim -g "$region" "$file"', folder, name, "");
    }

    // La pantalla entera de un monitor (su nombre de Hyprland, p. ej. HDMI-A-1).
    // Sin nombre, todas las pantallas en una sola imagen.
    function screenshotOutput(output, folder, name): void {
        root._capture('if [ -n "$3" ]; then grim -o "$3" "$file"; else grim "$file"; fi',
                      folder, name, output || "");
    }

    function pickColor(): void {
        Quickshell.execDetached(["hyprpicker", "--autocopy"]);
    }

    // Los datos van como argumentos ($1 carpeta, $2 archivo, $3 monitor) y no
    // pegados al texto del script: un nombre con espacios o comillas no rompe
    // nada.
    function _capture(grab, folder, name, output): void {
        Quickshell.execDetached(["sh", "-c",
            'dir="$(xdg-user-dir PICTURES 2>/dev/null || echo "$HOME/Pictures")/$1"; '
            + 'mkdir -p "$dir"; '
            + 'file="$dir/$2"; '
            + grab + ' && wl-copy < "$file"',
            "sh", folder, name, output]);
    }
}
