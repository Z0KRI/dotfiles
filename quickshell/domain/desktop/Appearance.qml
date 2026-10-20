// CASO DE USO: modo oscuro.
// Reglas:
//   - Cambia tu shell (Theme.isDark) y también las apps (color-scheme).
//   - Se recuerda entre reinicios.
//   - El tema solo pinta: quien decide el modo es esta regla.

pragma Singleton

import QtQuick
import Quickshell
import qs.core.theme
import qs.data.system

Singleton {
    id: root

    readonly property bool dark: PreferencesRepository.dark

    function toggle(): void {
        PreferencesRepository.dark = !root.dark;
    }

    function apply(): void {
        Theme.isDark = root.dark;
        ColorSchemeRepository.setDark(root.dark);
    }

    onDarkChanged: root.apply()
    Component.onCompleted: root.apply()
}