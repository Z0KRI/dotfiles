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
import qs.data.system

Singleton {
    id: root

    readonly property bool volume: PreferencesRepository.islandVolume
    readonly property bool player: PreferencesRepository.islandPlayer
    readonly property bool expandOnHover: PreferencesRepository.islandExpandOnHover

    // ¿Puede salir este ocupante? Los que no están en la lista, siempre.
    function allows(name): bool {
        if (name === "volume")
            return root.volume;
        if (name === "player")
            return root.player;
        return true;
    }

    function setVolume(on): void {
        PreferencesRepository.islandVolume = on;
    }

    function setPlayer(on): void {
        PreferencesRepository.islandPlayer = on;
    }

    function setExpandOnHover(on): void {
        PreferencesRepository.islandExpandOnHover = on;
    }
}
