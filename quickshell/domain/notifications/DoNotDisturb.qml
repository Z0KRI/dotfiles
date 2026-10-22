// CASO DE USO: No molestar (el "Foco" de macOS).
// Reglas:
//   - Activo: las notificaciones nuevas no salen en la isla, pero sí
//     quedan en el historial.
//   - Las llamadas del iPhone pueden saltárselo (Ajustes › Notificaciones).
//   - Se recuerda entre reinicios.

pragma Singleton

import Quickshell
import qs.data.system

Singleton {
    id: root

    readonly property bool active: PreferencesRepository.doNotDisturb
    readonly property bool allowCalls: PreferencesRepository.dndAllowCalls
    readonly property string status: root.active ? "Activado" : "Desactivado"

    function setActive(on): void {
        PreferencesRepository.doNotDisturb = on;
    }

    function toggle(): void {
        root.setActive(!root.active);
    }

    function setAllowCalls(on): void {
        PreferencesRepository.dndAllowCalls = on;
    }
}
