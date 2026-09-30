pragma Singleton

// La REGLA del volumen, no el dato. El repositorio da 0.0–1.0; aquí se decide
// que el usuario piensa en porcentajes, qué glifo le toca a cada tramo y cómo
// se escribe el silencio.
//
// La UI se enlaza aquí y nunca a Pipewire.

import QtQuick
import Quickshell
import qs.data.audio

Singleton {
    id: root

    readonly property bool ready: AudioRepository.ready
    readonly property bool muted: AudioRepository.muted
    readonly property int percent: Math.round(AudioRepository.volume * 100)

    // Glifos de tu Nerd Font (rango Font Awesome, igual que tu "\uf002").
    readonly property string icon: {
        if (root.muted || root.percent === 0)
            return "\uf026"
        if (root.percent < 50)
            return "\uf027"
        return "\uf028"
    }

    readonly property string label: root.muted
        ? "Silenciado"
        : root.percent + "%"

    signal changed()

    function setPercent(value): void {
        AudioRepository.setVolume(value / 100);
    }

    function toggleMuted(): void {
        AudioRepository.setMuted(!AudioRepository.muted);
    }

    Connections {
        target: AudioRepository

        function onChanged() { root.changed() }
    }
}