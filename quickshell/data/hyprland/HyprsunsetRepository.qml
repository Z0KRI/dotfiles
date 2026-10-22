// REPOSITORIO: hyprsunset (filtro de luz y brillo por gamma de Hyprland),
// vía su IPC en hyprctl. Necesita hyprsunset corriendo.
//
// Temperatura y gamma son independientes: hyprsunset primero arma el color
// (la temperatura, o "identidad" = sin filtro) y luego le multiplica la gamma.
// Por eso apagar la luz nocturna no te regresa el brillo al 100 %.

pragma Singleton

import Quickshell

Singleton {
    // percent: 100 = brillo normal.
    function setGamma(percent): void {
        Quickshell.execDetached(["hyprctl", "hyprsunset", "gamma", String(percent)]);
    }

    // kelvin: de 1000 a 20000. 6500 es luz de día; menos es más cálido.
    function setTemperature(kelvin): void {
        Quickshell.execDetached(["hyprctl", "hyprsunset", "temperature", String(kelvin)]);
    }

    // Quita el filtro de color (la gamma se queda como esté).
    function clearTemperature(): void {
        Quickshell.execDetached(["hyprctl", "hyprsunset", "identity"]);
    }
}
