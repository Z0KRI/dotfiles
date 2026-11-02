// CASO DE USO: el fondo de pantalla.
// Reglas:
//   - Los fondos son las imágenes de ~/Pictures/Wallpapers, por nombre. Se
//     agregan y se quitan solos al cambiar la carpeta (WallpaperRepository).
//   - El elegido se recuerda entre reinicios. Si lo borras de la carpeta, se
//     usa el primero; si la carpeta está vacía, no hay fondo de la shell y se
//     ve el de Hyprland.
//   - El mismo en todos los monitores.
//   - El selector sale del borde de abajo, como Mission Control, y comparte
//     ese borde con Spotlight y el portapapeles (BottomEdge).
//
// Por IPC (modules/wallpaper): toggle | open | close | next | previous

pragma Singleton

import Quickshell
import qs.data.system
import qs.data.wallpaper

Singleton {
    id: root

    readonly property var list: WallpaperRepository.files
    readonly property bool loaded: WallpaperRepository.loaded
    readonly property bool empty: root.list.length === 0

    // Para decirlo en pantalla: "~/Pictures/Wallpapers".
    readonly property string folder: WallpaperRepository.folder
        .replace(Quickshell.env("HOME"), "~")

    // El elegido, ya resuelto contra lo que hay en la carpeta.
    readonly property var current: {
        const saved = PreferencesRepository.wallpaper;
        return root.list.find(entry => entry.path === saved) ?? root.list[0] ?? null;
    }

    readonly property string source: root.current ? root.current.url : ""

    function choose(entry): void {
        if (entry && entry.path)
            PreferencesRepository.wallpaper = entry.path;
    }

    // El siguiente o el anterior, dando la vuelta.
    function step(delta): void {
        if (root.empty)
            return;

        const at = root.current ? root.list.findIndex(entry => entry.path === root.current.path) : -1;
        const count = root.list.length;
        root.choose(root.list[((at + delta) % count + count) % count]);
    }

    function openFolder(): void {
        WallpaperRepository.openFolder();
    }

    // ── el selector ───────────────────────────────────────────────
    readonly property bool shown: BottomEdge.owner === "wallpaper"

    function open(): void {
        BottomEdge.claim("wallpaper");
    }

    function close(): void {
        BottomEdge.release("wallpaper");
    }

    function toggle(): void {
        if (root.shown)
            root.close();
        else
            root.open();
    }
}
