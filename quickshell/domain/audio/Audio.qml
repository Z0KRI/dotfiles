// CASO DE USO: el sonido del equipo.
// Reglas:
//   - El volumen va de 0 a 100%: nunca se amplifica por encima.
//   - Subir el volumen quita el silencio.
//   - Tipo de salida: Bluetooth = audífonos, HDMI/DisplayPort = pantalla,
//     lo demás = bocinas.
//   - Tramo del volumen (el ícono): silenciado o en 0; bajo hasta un tercio;
//     medio hasta dos tercios; alto.
//   - En texto: "Silenciado" o el porcentaje.

pragma Singleton

import QtQuick
import Quickshell
import qs.data.audio
import qs.data.applications
import qs.domain.launcher

Singleton {
    id: root

    readonly property real volume: AudioRepository.volume
    readonly property bool muted: AudioRepository.muted
    readonly property int percent: Math.round(root.volume * 100)

    // "muted" | "low" | "medium" | "high": la vista elige el ícono con esto
    // (Theme.systemIcons.volume[level]).
    readonly property string level: {
        if (root.muted || root.percent === 0)
            return "muted";
        if (root.percent < 34)
            return "low";
        if (root.percent < 67)
            return "medium";
        return "high";
    }

    readonly property string label: root.muted ? "Silenciado" : root.percent + "%"

    // Cambió el volumen o el silencio (la isla lo enseña un momento).
    signal changed()

    Connections {
        target: AudioRepository

        function onChanged() {
            root.changed();
        }
    }

    readonly property var outputs: AudioRepository.outputs.map(output => ({
        id: output.id,
        label: output.label,
        kind: root.kindOf(output.name),
        selected: output.id === AudioRepository.currentOutputId
    }))

    readonly property var settingsApp: AppRepository.entryFor("org.pulseaudio.pavucontrol")
    readonly property bool hasSettingsApp: root.settingsApp !== null

    function setVolume(value): void {
        const clamped = Math.max(0, Math.min(1, value));
        AudioRepository.setVolume(clamped);

        if (clamped > 0 && root.muted)
            AudioRepository.setMuted(false);
    }

    function toggleMuted(): void {
        AudioRepository.setMuted(!root.muted);
    }

    function selectOutput(id): void {
        AudioRepository.setOutput(id);
    }

    function openSettings(): void {
        if (root.settingsApp)
            LaunchApp.execute(root.settingsApp);
    }

    function kindOf(nodeName) {
        if (nodeName.startsWith("bluez"))
            return "headphones";
        if (/hdmi|displayport/i.test(nodeName))
            return "display";
        return "speaker";
    }
}