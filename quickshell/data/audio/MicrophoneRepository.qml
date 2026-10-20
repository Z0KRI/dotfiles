// REPOSITORIO: el micrófono por defecto (entrada de Pipewire).
// Datos planos; nunca nodos de Pipewire.

pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var source: Pipewire.defaultAudioSource

    readonly property bool available: root.source !== null
    readonly property real volume: root.source?.audio?.volume ?? 0
    readonly property bool muted: root.source?.audio?.muted ?? false

    function setVolume(value): void {
        if (root.source?.audio)
            root.source.audio.volume = value;
    }

    function setMuted(value): void {
        if (root.source?.audio)
            root.source.audio.muted = value;
    }

    // Pipewire solo reporta volumen y silencio de los nodos "enlazados".
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSource]
    }
}