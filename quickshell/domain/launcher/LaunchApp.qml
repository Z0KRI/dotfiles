// CASO DE USO: abrir una app desde Spotlight (o desde otro dominio, como el
// reloj o los botones de "Configuración avanzada…").
// Reglas:
//   - Se anota en el historial antes de abrirla.
//   - Si ya tiene una ventana abierta, vas a esa ventana (y a su escritorio)
//     en vez de abrir otra. Es lo que hacía `window` antes de `drun` en tu
//     combi de rofi: escribir "firefox" te lleva al Firefox que ya tienes.
//   - newInstance (Ctrl + Enter en Spotlight) abre otra aunque haya ventana.

pragma Singleton

import Quickshell
import qs.data.applications
import qs.data.hyprland

Singleton {
    id: root

    // id del .desktop → su primera ventana abierta.
    //
    // Se arma una vez cada vez que cambian las ventanas, no una vez por app:
    // en el modo Aplicaciones se preguntaría por 150 apps en cada tecla, y
    // así cada pregunta es solo buscar en un objeto.
    //
    // La clase de una ventana no siempre es el id de su .desktop (Ghostty es
    // com.mitchellh.ghostty y su .desktop también, pero Chrome es
    // google-chrome y su .desktop es google-chrome.desktop… a veces). La
    // búsqueda heurística de Quickshell resuelve esas diferencias.
    readonly property var windowsById: {
        const map = {};
        for (const toplevel of HyprlandRepository.toplevels) {
            const entry = AppRepository.entryFor(HyprlandRepository.appIdOf(toplevel));
            if (entry && !map[entry.id])
                map[entry.id] = toplevel;
        }
        return map;
    }

    function windowFor(entry) {
        return entry ? (root.windowsById[entry.id] ?? null) : null;
    }

    function execute(entry, newInstance): void {
        if (!entry)
            return;

        // Solo cuenta si el historial está activado (Ajustes › Spotlight).
        LaunchHistory.record(entry.id);

        const window = newInstance ? null : root.windowFor(entry);
        if (window)
            HyprlandRepository.focus(window);
        else
            AppRepository.launch(entry);
    }
}
