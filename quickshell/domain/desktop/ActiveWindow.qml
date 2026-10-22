// CASO DE USO: el nombre de la app activa en la barra (como el menú de la
// app en macOS).
// Reglas:
//   - Sin ventana: "Desktop".
//   - Algunas apps tienen un nombre corto fijo (la tabla de abajo; la clase se
//     ve con `hyprctl clients`).
//   - Las demás, el nombre de su .desktop; si no hay, la clase tal cual.

pragma Singleton

import Quickshell
import qs.data.hyprland
import qs.data.applications

Singleton {
    id: root

    readonly property string emptyName: "Desktop"

    readonly property var names: [
        [/^firefox$/, "Firefox"],
        [/^(zen|app\.zen_browser\.zen)$/, "Zen"],
        [/^google-chrome$/, "Chrome"],
        [/^com\.mitchellh\.ghostty$/, "Terminal"],
        [/^code-oss$/, "Code"],
        [/^org\.gnome\.Nautilus$/, "Files"],
        [/^font-manager$/, "Font Manager"],
    ]

    function isEmpty(screen) {
        return HyprlandRepository.activeAppIdFor(screen) === "";
    }

    function nameFor(screen) {
        const appId = HyprlandRepository.activeAppIdFor(screen);

        if (appId === "")
            return root.emptyName;

        const rule = root.names.find(([pattern]) => pattern.test(appId));
        if (rule)
            return rule[1];

        return AppRepository.nameFor(appId) || appId;
    }
}