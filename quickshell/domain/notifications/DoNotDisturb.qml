// CASO DE USO: No molestar (el "Foco" de macOS).
// Reglas:
//   - Activo: las notificaciones nuevas no salen en la isla, pero sí
//     quedan en el historial.
//   - Se recuerda entre reinicios.

pragma Singleton

import Quickshell
import qs.data.system

Singleton {
    id: root

    readonly property bool active: PreferencesRepository.doNotDisturb
    readonly property string status: root.active ? "Activado" : "Desactivado"

    function toggle(): void {
        PreferencesRepository.doNotDisturb = !root.active;
    }
}