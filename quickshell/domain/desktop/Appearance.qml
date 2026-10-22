// CASO DE USO: la apariencia (modo claro/oscuro, color de acento y Liquid Glass).
// Reglas:
//   - Tres modos: claro, oscuro y automático. Automático es oscuro de
//     7 p.m. a 7 a.m.
//   - El modo cambia tu shell (Theme.isDark) y también las apps (color-scheme).
//   - El botón del Centro de control alterna claro/oscuro y apaga el
//     automático: si lo tocas, es porque quieres ese modo ahora.
//   - Se recuerda entre reinicios.
//   - El tema solo pinta: quien decide es esta regla.

pragma Singleton

import QtQuick
import Quickshell
import qs.core.theme
import qs.data.system
import qs.data.time

Singleton {
    id: root

    readonly property var modes: ["light", "dark", "auto"]
    readonly property var accentIds: ["blue", "purple", "pink", "red", "orange", "yellow", "green", "graphite"]

    readonly property int nightStarts: 19
    readonly property int nightEnds: 7

    readonly property string mode: {
        if (PreferencesRepository.autoAppearance)
            return "auto";
        return PreferencesRepository.dark ? "dark" : "light";
    }

    readonly property bool night: {
        const hour = ClockRepository.now.getHours();
        return hour >= root.nightStarts || hour < root.nightEnds;
    }

    readonly property bool dark: root.mode === "auto" ? root.night : PreferencesRepository.dark

    // Un acento desconocido (un JSON editado a mano) cae en azul.
    readonly property string accent: root.accentIds.indexOf(PreferencesRepository.accent) >= 0
        ? PreferencesRepository.accent
        : "blue"

    readonly property real glass: Math.max(0, Math.min(1, PreferencesRepository.glass))

    function setMode(mode): void {
        if (root.modes.indexOf(mode) < 0)
            return;

        PreferencesRepository.autoAppearance = mode === "auto";
        if (mode !== "auto")
            PreferencesRepository.dark = mode === "dark";
    }

    function toggle(): void {
        root.setMode(root.dark ? "light" : "dark");
    }

    function setAccent(id): void {
        if (root.accentIds.indexOf(id) >= 0)
            PreferencesRepository.accent = id;
    }

    function setGlass(value): void {
        PreferencesRepository.glass = Math.max(0, Math.min(1, value));
    }

    function applyMode(): void {
        Theme.isDark = root.dark;
        ColorSchemeRepository.setDark(root.dark);
    }

    onDarkChanged: root.applyMode()
    onAccentChanged: Theme.accentName = root.accent
    onGlassChanged: Theme.glassTint = root.glass

    Component.onCompleted: {
        root.applyMode();
        Theme.accentName = root.accent;
        Theme.glassTint = root.glass;
    }
}
