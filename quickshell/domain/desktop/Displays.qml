// CASO DE USO: los monitores, para mostrarlos en Ajustes.
// Reglas:
//   - Solo se informan: la resolución y la posición viven en tu config de
//     Hyprland (hosts/<equipo>.lua), que es donde deben cambiarse.
//   - Detalle: "2560 × 1440 · 144 Hz · escala 1.25". La frecuencia se
//     redondea y la escala solo aparece si no es 1.
//   - Orden: el monitor enfocado primero.

pragma Singleton

import Quickshell
import qs.data.hyprland

Singleton {
    id: root

    readonly property var monitors: HyprlandRepository.monitors
        .map(monitor => ({
            name: monitor.name,
            title: monitor.description || monitor.name,
            detail: root.detailOf(monitor),
            focused: monitor.focused
        }))
        .sort((a, b) => b.focused - a.focused);

    function detailOf(monitor) {
        const parts = [monitor.width + " × " + monitor.height];

        if (monitor.refreshRate > 0)
            parts.push(Math.round(monitor.refreshRate) + " Hz");

        if (Math.abs(monitor.scale - 1) > 0.001)
            parts.push("escala " + Number(monitor.scale.toFixed(2)));

        return monitor.name + " · " + parts.join(" · ");
    }
}
