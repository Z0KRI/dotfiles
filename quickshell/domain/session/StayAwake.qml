// CASO DE USO: No suspender.
// Reglas:
//   - Activo: la pantalla no se apaga ni se bloquea por inactividad.
//   - No se recuerda entre reinicios: olvidarlo encendido no debe dejar
//     la PC despierta para siempre.

pragma Singleton

import Quickshell
import qs.data.system

Singleton {
    id: root

    readonly property bool active: IdleRepository.inhibited

    function toggle(): void {
        IdleRepository.setInhibited(!root.active);
    }
}