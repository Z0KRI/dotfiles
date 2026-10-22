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
