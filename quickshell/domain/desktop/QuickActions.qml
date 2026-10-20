// CASO DE USO: accesos rápidos del Centro de control.
// Reglas:
//   - Captura: eliges una zona; se guarda en Imágenes/Capturas con fecha
//     y hora en el nombre, y queda en el portapapeles.
//   - Selector de color: el color queda en el portapapeles.

pragma Singleton

import QtQuick
import Quickshell
import qs.data.system

Singleton {
    function screenshot(): void {
        const stamp = Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss");
        CaptureRepository.screenshotRegion("Capturas", "Captura_" + stamp + ".png");
    }

    function pickColor(): void {
        CaptureRepository.pickColor();
    }
}