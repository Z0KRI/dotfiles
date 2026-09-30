pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Services.Pipewire

Singleton {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink

    readonly property real volume: root.sink?.audio?.volume ?? 0
    readonly property bool muted: root.sink?.audio?.muted ?? false
    readonly property int currentOutputId: root.sink?.id ?? -1

    // Salidas de hardware (bocinas, audífonos, HDMI), no programas.
    readonly property var outputs: Pipewire.nodes.values
        .filter(node => node.isSink && !node.isStream && node.audio)
        .map(node => ({
            id: node.id,
            name: node.name,
            label: node.description || node.nickname || node.name
        }))

    function setVolume(value): void {
        if (root.sink?.audio)
            root.sink.audio.volume = value;
    }

    function setMuted(value): void {
        if (root.sink?.audio)
            root.sink.audio.muted = value;
    }

    function setOutput(id): void {
        const node = Pipewire.nodes.values.find(n => n.id === id);
        if (node)
            Pipewire.preferredDefaultAudioSink = node;
    }

    // Pipewire solo reporta volumen y silencio de los nodos "enlazados".
    PwObjectTracker {
        objects: [Pipewire.defaultAudioSink]
    }
}