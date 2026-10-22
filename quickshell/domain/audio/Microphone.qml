// CASO DE USO: el micrófono.
// Reglas:
//   - De 0 a 100%: nunca se amplifica por encima.
//   - Subir el volumen quita el silencio.
//   - En silencio, el deslizador se ve en cero.
//   - Tipo de entrada: Bluetooth = audífonos; lo demás, micrófono.

pragma Singleton

import Quickshell
import qs.data.audio

Singleton {
    id: root

    readonly property bool available: MicrophoneRepository.available
    readonly property bool muted: MicrophoneRepository.muted
    readonly property real volume: MicrophoneRepository.volume

    readonly property real shownVolume: root.muted ? 0 : root.volume
    readonly property bool silent: root.muted || root.volume <= 0

    readonly property var inputs: MicrophoneRepository.inputs.map(input => ({
        id: input.id,
        label: input.label,
        kind: input.name.startsWith("bluez") ? "headphones" : "mic",
        selected: input.id === MicrophoneRepository.currentInputId
    }))

    function setVolume(value): void {
        const clamped = Math.max(0, Math.min(1, value));
        MicrophoneRepository.setVolume(clamped);

        if (clamped > 0 && root.muted)
            MicrophoneRepository.setMuted(false);
    }

    function toggleMute(): void {
        MicrophoneRepository.setMuted(!root.muted);
    }

    function selectInput(id): void {
        MicrophoneRepository.setInput(id);
    }
}
