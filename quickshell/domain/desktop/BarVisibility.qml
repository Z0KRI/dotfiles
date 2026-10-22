// CASO DE USO: cuándo se ve la barra y qué muestra.
// Reglas:
//   - Ocultar automáticamente tiene tres modos:
//       "always"     siempre se oculta, salvo en los escritorios fijos;
//       "fullscreen" solo con una app en pantalla completa (lo de siempre);
//       "never"      nunca se oculta.
//   - En los escritorios fijos la barra nunca se oculta.
//   - Mientras se oculta sola, no empuja ventanas y se ve sólida de lado a lado.
//   - Con una app en pantalla completa sube de capa para verse encima.

pragma Singleton

import Quickshell
import qs.data.hyprland
import qs.data.system

Singleton {
    id: root

    readonly property var modes: ["always", "fullscreen", "never"]

    readonly property string mode: root.modes.indexOf(PreferencesRepository.barAutoHide) >= 0
        ? PreferencesRepository.barAutoHide
        : "fullscreen"

    readonly property var pinnedWorkspaces: PreferencesRepository.barPinnedWorkspaces ?? []

    readonly property bool showActiveApp: PreferencesRepository.barShowActiveApp

    function isPinned(screen) {
        return root.pinnedWorkspaces.indexOf(HyprlandRepository.activeWorkspaceId(screen)) >= 0;
    }

    function isFullscreen(screen) {
        return HyprlandRepository.hasFullscreen(screen);
    }

    function autoHide(screen) {
        if (root.isPinned(screen))
            return false;

        if (root.mode === "always")
            return true;

        if (root.mode === "fullscreen")
            return root.isFullscreen(screen);

        return false;
    }

    // Si se oculta sola, no reserva espacio; en pantalla completa tampoco:
    // ahí no hay nada que empujar.
    function reserveSpace(screen) {
        return !root.autoHide(screen) && !root.isFullscreen(screen);
    }

    // To view an app in full-screen mode, you need to switch to a higher layer.
    function aboveFullscreen(screen) {
        return root.isFullscreen(screen);
    }

    // When it's hidden on its own, it appears as a solid bar.
    function solid(screen) {
        return root.autoHide(screen);
    }

    // ── Ajustes ─────────────────────────────────────────────

    function setMode(mode): void {
        if (root.modes.indexOf(mode) >= 0)
            PreferencesRepository.barAutoHide = mode;
    }

    function isPinnedWorkspace(id) {
        return root.pinnedWorkspaces.indexOf(id) >= 0;
    }

    // Se arma una lista nueva en vez de modificar la vieja: si cambias el
    // contenido de un arreglo sin reasignarlo, nadie se entera del cambio.
    function togglePinned(id): void {
        const list = root.pinnedWorkspaces.filter(item => item !== id);
        if (list.length === root.pinnedWorkspaces.length)
            list.push(id);

        PreferencesRepository.barPinnedWorkspaces = list.sort((a, b) => a - b);
    }

    function setShowActiveApp(on): void {
        PreferencesRepository.barShowActiveApp = on;
    }
}
