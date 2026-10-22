// CASO DE USO: luz nocturna (el Night Shift de macOS), con hyprsunset.
// Reglas:
//   - Apagada: sin filtro de color. Encendida: la temperatura elegida.
//   - La temperatura va de 6000 K (casi neutra) a 2500 K (muy cálida).
//     El deslizador habla de "calidez": 0 = menos cálida, 1 = más cálida.
//   - Mientras arrastras se aplica como mucho cada 60 ms (throttle, igual
//     que el brillo).
//   - Se recuerda entre reinicios y se vuelve a aplicar al iniciar.

pragma Singleton

import QtQuick
import Quickshell
import qs.data.system
import qs.data.hyprland

Singleton {
    id: root

    readonly property int coolest: 6000
    readonly property int warmest: 2500

    readonly property bool enabled: PreferencesRepository.nightLight

    readonly property int temperature: Math.max(root.warmest,
        Math.min(root.coolest, PreferencesRepository.nightTemperature))

    readonly property real warmth: (root.coolest - root.temperature) / (root.coolest - root.warmest)

    function setEnabled(on): void {
        PreferencesRepository.nightLight = on;
    }

    function toggle(): void {
        root.setEnabled(!root.enabled);
    }

    function setWarmth(value): void {
        const clamped = Math.max(0, Math.min(1, value));
        PreferencesRepository.nightTemperature =
            Math.round(root.coolest - clamped * (root.coolest - root.warmest));
    }

    function apply(): void {
        if (root.enabled)
            HyprsunsetRepository.setTemperature(root.temperature);
        else
            HyprsunsetRepository.clearTemperature();
    }

    function schedule(): void {
        if (!throttle.running)
            throttle.start();
    }

    onEnabledChanged: root.schedule()
    onTemperatureChanged: {
        if (root.enabled)
            root.schedule();
    }

    Component.onCompleted: {
        root.schedule();
        // hyprsunset arranca a la par que tu shell. Si todavía no estaba
        // escuchando, este segundo intento lo alcanza.
        retry.start();
    }

    Timer {
        id: throttle
        interval: 60
        onTriggered: root.apply()
    }

    Timer {
        id: retry
        interval: 3000
        onTriggered: root.apply()
    }
}
