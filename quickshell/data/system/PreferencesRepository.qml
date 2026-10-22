// REPOSITORIO: todas las preferencias de tu shell que sobreviven a
// reinicios. Las usan el Centro de control y Ajustes. Se guardan en JSON,
// igual que el historial del launcher.
//
// Dos cosas que conviene saber:
//
// 1. Una clave que no está en el archivo conserva su valor por defecto. Por
//    eso agregar una preferencia nueva no rompe tu preferences.json viejo:
//    la primera vez que cambies algo, se escribe con todas las claves.
// 2. Se guarda con un pequeño retraso (debounce). Un deslizador manda decenas
//    de cambios por segundo; sin esto, cada pixel sería una escritura a disco.
//    Mientras haya un guardado pendiente no se recarga el archivo: si no, la
//    versión vieja del disco pisaría lo que acabas de mover.

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    // ── Apariencia ──────────────────────────────────────────
    property alias dark: adapter.dark
    property alias autoAppearance: adapter.autoAppearance
    property alias accent: adapter.accent
    property alias glass: adapter.glass

    // ── Pantallas ───────────────────────────────────────────
    property alias brightness: adapter.brightness
    property alias nightLight: adapter.nightLight
    property alias nightTemperature: adapter.nightTemperature

    // ── Notificaciones ──────────────────────────────────────
    property alias doNotDisturb: adapter.doNotDisturb
    property alias dndAllowCalls: adapter.dndAllowCalls
    property alias notificationBanners: adapter.notificationBanners
    property alias notificationApps: adapter.notificationApps

    // ── Barra de menús ──────────────────────────────────────
    property alias barAutoHide: adapter.barAutoHide
    property alias barPinnedWorkspaces: adapter.barPinnedWorkspaces
    property alias barShowActiveApp: adapter.barShowActiveApp
    property alias clockShowDate: adapter.clockShowDate
    property alias clock24h: adapter.clock24h

    // ── Isla ────────────────────────────────────────────────
    property alias islandVolume: adapter.islandVolume
    property alias islandPlayer: adapter.islandPlayer
    property alias islandExpandOnHover: adapter.islandExpandOnHover

    // ── Spotlight ───────────────────────────────────────────
    property alias launcherHistory: adapter.launcherHistory

    FileView {
        id: file

        path: Quickshell.statePath("preferences.json")
        watchChanges: true

        onFileChanged: {
            if (!saveTimer.running)
                reload();
        }

        onAdapterUpdated: saveTimer.restart()

        // La primera vez el archivo no existe: se crea con los valores por defecto.
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter();
        }

        JsonAdapter {
            id: adapter

            property bool dark: false
            property bool autoAppearance: false
            property string accent: "blue"
            property real glass: 0.5            // 0 transparente · 1 tintado

            property real brightness: 1.0
            property bool nightLight: false
            property int nightTemperature: 4000 // kelvin

            property bool doNotDisturb: false
            property bool dndAllowCalls: true
            property bool notificationBanners: true

            // Una entrada por app que te ha notificado:
            // { name: "WhatsApp", phone: true, allowed: true }
            property var notificationApps: []

            property string barAutoHide: "fullscreen" // always | fullscreen | never
            property var barPinnedWorkspaces: [1]
            property bool barShowActiveApp: true
            property bool clockShowDate: true
            property bool clock24h: false

            property bool islandVolume: true
            property bool islandPlayer: true
            property bool islandExpandOnHover: true

            property bool launcherHistory: true
        }
    }

    Timer {
        id: saveTimer
        interval: 250
        onTriggered: file.writeAdapter()
    }
}
