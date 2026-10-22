// CASO DE USO: el historial de Spotlight (qué apps abres y cuántas veces).
// Reglas:
//   - Activado: se cuenta cada app que abres y las más usadas salen primero.
//   - Desactivado: no se cuenta nada nuevo y el orden es alfabético. El
//     historial que ya había no se borra; para eso está clear().

pragma Singleton

import Quickshell
import qs.data.system
import qs.data.usage

Singleton {
    id: root

    readonly property bool enabled: PreferencesRepository.launcherHistory
    readonly property int appCount: UsageRepository.appCount

    function setEnabled(on): void {
        PreferencesRepository.launcherHistory = on;
    }

    // Cuántas veces la abriste, o 0 si el historial está apagado.
    function countFor(appId): int {
        return root.enabled ? UsageRepository.countFor(appId) : 0;
    }

    function record(appId): void {
        if (root.enabled)
            UsageRepository.record(appId);
    }

    function clear(): void {
        UsageRepository.clear();
    }
}
