// CASO DE USO: abrir una app desde Spotlight (o desde otro dominio, como el
// reloj o los botones de "Configuración avanzada…").
// Reglas:
//   - Se anota en el historial antes de abrirla.

pragma Singleton

import Quickshell
import qs.data.applications

Singleton {
    id: root

    function execute(entry): void {
        if (!entry)
            return;

        // Solo cuenta si el historial está activado (Ajustes › Spotlight).
        LaunchHistory.record(entry.id);
        AppRepository.launch(entry);
    }
}
