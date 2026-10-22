// CASO DE USO: brillo de la pantalla (gamma de hyprsunset).
// Reglas:
//   - El deslizador va de 0 a 1, pero la pantalla nunca baja de 20%:
//     con gamma se puede llegar a negro y quedarte sin ver nada.
//   - Mientras arrastras se aplica como mucho cada 60 ms.
//   - Se recuerda entre reinicios y se vuelve a aplicar al iniciar.

pragma Singleton

import QtQuick
import Quickshell
import qs.data.system
import qs.data.hyprland

Singleton {
    id: root

    readonly property real minimum: 0.2
    readonly property real value: PreferencesRepository.brightness

    readonly property int gamma: Math.round((root.minimum + root.value * (1 - root.minimum)) * 100)

    function setValue(value): void {
        PreferencesRepository.brightness = Math.max(0, Math.min(1, value));
    }

    // Throttle: si ya hay una aplicación en camino, no se agenda otra;
    // cuando sale, toma el valor más reciente.
    function schedule(): void {
        if (!throttle.running)
            throttle.start();
    }

    onGammaChanged: root.schedule()

    Component.onCompleted: {
        root.schedule();
        // hyprsunset arranca a la par que tu shell (autostart de Hyprland).
        // Si todavía no estaba escuchando, este segundo intento lo alcanza.
        // Es la misma regla que la luz nocturna.
        retry.start();
    }

    Timer {
        id: throttle
        interval: 60
        onTriggered: HyprsunsetRepository.setGamma(root.gamma)
    }

    Timer {
        id: retry
        interval: 3000
        onTriggered: HyprsunsetRepository.setGamma(root.gamma)
    }
}