// CASO DE USO: el sonido del equipo.
// Reglas:
//   - El volumen va de 0 a 100%: nunca se amplifica por encima.
//   - Cada paso de la rueda mueve 5%.
//   - Subir el volumen quita el silencio.
//   - El ícono tiene 4 niveles: silencio, bajo, medio y alto.
//   - Tipo de salida: Bluetooth = audífonos, HDMI/DisplayPort = pantalla,
//     lo demás = bocinas.

pragma Singleton

import Quickshell
import qs.data.audio
import qs.data.applications
import qs.domain.launcher

Singleton {
    id: root

    readonly property real step: 0.05

    readonly property real volume: AudioRepository.volume
    readonly property bool muted: AudioRepository.muted
    readonly property int percent: Math.round(root.volume * 100)

    readonly property string level: {
        if (root.muted || root.volume <= 0)
            return "muted";
        if (root.volume < 0.34)
            return "low";
        if (root.volume < 0.67)
            return "medium";
        return "high";
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

    // steps: +1 sube un paso, -1 baja un paso.
    function nudge(steps): void {
        root.setVolume(root.volume + steps * root.step);
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