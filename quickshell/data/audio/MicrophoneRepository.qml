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
    readonly property int currentInputId: root.source?.id ?? -1

    // Entradas de hardware (micrófonos, la entrada de línea), no programas.
    // Es el mismo filtro que las salidas de AudioRepository, con isSink al
    // revés. Los "monitor" de Pipewire (lo que suena, visto como entrada) no
    // son micrófonos: se dejan fuera.
    readonly property var inputs: Pipewire.nodes.values
        .filter(node => !node.isSink && !node.isStream && node.audio
                        && !/\.monitor$/.test(node.name))
        .map(node => ({
            id: node.id,
            name: node.name,
            label: node.description || node.nickname || node.name
        }))

    function setVolume(value): void {
        if (root.source?.audio)
            root.source.audio.volume = value;
    }

    function setMuted(value): void {
        if (root.source?.audio)
            root.source.audio.muted = value;
    }

    function setInput(id): void {
        const node = Pipewire.nodes.values.find(n => n.id === id);
        if (node)
            Pipewire.preferredDefaultAudioSource = node;
    }

    // Pipewire solo reporta volumen y silencio de los nodos "enlazados".
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSource]
    }
}
