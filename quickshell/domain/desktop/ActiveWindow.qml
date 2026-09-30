pragma Singleton

import Quickshell
import qs.data.hyprland
import qs.data.applications

Singleton {
    id: root

    readonly property string emptyName: "Desktop"

    readonly property var names: [
        [/^firefox$/, "Firefox"],
        [/^zen$/, "Zen"],
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