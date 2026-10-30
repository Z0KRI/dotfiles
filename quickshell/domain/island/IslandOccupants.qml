pragma Singleton

// Qué ocupantes pueden salir en la isla, y cómo se abren. Lo decide el
// usuario en Ajustes; el árbitro de `Island.qml` y el contrato del ocupante
// solo preguntan aquí.
//
// Las notificaciones NO se apagan aquí sino en su propio dominio
// (NotificationSettings): una notificación silenciada igual se guarda en el
// historial, y una llamada tiene sus propias reglas. Apagarla en el árbitro
// la dejaría a medias.

import QtQuick
import Quickshell
import qs.data.hyprland
import qs.data.system

Singleton {
    id: root

    readonly property bool volume: PreferencesRepository.islandVolume
    readonly property bool player: PreferencesRepository.islandPlayer
    readonly property bool airpods: PreferencesRepository.islandAirPods
    readonly property bool keyboard: PreferencesRepository.islandKeyboard
    readonly property bool brightness: PreferencesRepository.islandBrightness
    readonly property bool expandOnHover: PreferencesRepository.islandExpandOnHover

    // ¿hay una app en pantalla completa donde sale la isla (el monitor
    // enfocado)? La música es un ocupante permanente y ahí se calla: encima de
    // un vídeo o un juego sería una mancha fija. Una notificación de cuatro
    // segundos sí sale.
    readonly property bool fullscreen: HyprlandRepository.focusedHasFullscreen

    // ¿Puede salir este ocupante? Los que no están en la lista, siempre.
    function allows(name): bool {
        if (name === "volume")
            return root.volume;
        if (name === "player")
            return root.player;
        if (name === "airpods")
            return root.airpods;
        if (name === "keyboard")
            return root.keyboard;
        if (name === "brightness")
            return root.brightness;
        return true;
    }

    function setVolume(on): void {
        PreferencesRepository.islandVolume = on;
    }

    function setPlayer(on): void {
        PreferencesRepository.islandPlayer = on;
    }

    function setAirPods(on): void {
        PreferencesRepository.islandAirPods = on;
    }

    function setKeyboard(on): void {
        PreferencesRepository.islandKeyboard = on;
    }

    function setBrightness(on): void {
        PreferencesRepository.islandBrightness = on;
    }

    function setExpandOnHover(on): void {
        PreferencesRepository.islandExpandOnHover = on;
    }
}
