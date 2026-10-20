// REPOSITORIO: hyprsunset (filtro de luz y brillo por gamma de Hyprland),
// vía su IPC en hyprctl. Necesita hyprsunset corriendo.

pragma Singleton

import Quickshell

Singleton {
    // percent: 100 = brillo normal.
    function setGamma(percent): void {
        Quickshell.execDetached(["hyprctl", "hyprsunset", "gamma", String(percent)]);
    }
}