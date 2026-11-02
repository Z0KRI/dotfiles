// CASO DE USO: cuándo se ve la barra y qué muestra.
// La barra es el marco: una figura negra alrededor de la pantalla con dos
// pestañas arriba. Reglas:
//   - El marco se ve siempre, salvo con una app en pantalla completa: ahí se
//     va y, si las pestañas se ven, cuelgan directo del borde de la pantalla.
//   - Ocultar automáticamente (las pestañas) tiene tres modos:
//       "always"     siempre se ocultan, salvo en los escritorios fijos;
//       "fullscreen" solo con una app en pantalla completa (lo de siempre);
//       "never"      nunca se ocultan.
//   - En los escritorios fijos las pestañas nunca se ocultan.
//   - Mientras se ocultan solas, no empujan ventanas (el marco sí) y, al
//     destaparse, la franja de arriba se ve sólida de lado a lado.
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

    // El marco (lados, abajo y la franja de arriba). Sobre un video o un
    // juego en pantalla completa estorbaría: se va.
    function framed(screen) {
        return !root.isFullscreen(screen);
    }

    // Lo mismo en el monitor enfocado, que es donde se abren Spotlight y el
    // portapapeles (sus ventanas no saben de antemano en qué pantalla salen:
    // las pone el compositor donde está el foco).
    readonly property bool focusedFramed: !HyprlandRepository.focusedHasFullscreen

    function autoHide(screen) {
        if (root.isPinned(screen))
            return false;

        if (root.mode === "always")
            return true;

        if (root.mode === "fullscreen")
            return root.isFullscreen(screen);

        return false;
    }

    // ¿Las pestañas apartan las ventanas? Si se ocultan solas, no; en
    // pantalla completa tampoco: ahí no hay nada que empujar. (El grosor del
    // marco se aparta siempre que haya marco: eso lo resuelve el módulo.)
    function reserveSpace(screen) {
        return !root.autoHide(screen) && !root.isFullscreen(screen);
    }

    // Para verse sobre una app en pantalla completa hay que subir de capa.
    function aboveFullscreen(screen) {
        return root.isFullscreen(screen);
    }

    // Si se oculta sola, al destaparse se ve como barra sólida de lado a lado.
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
