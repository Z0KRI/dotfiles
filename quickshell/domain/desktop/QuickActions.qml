// CASO DE USO: capturas y selector de color. Los usan el Centro de control
// (botones) y los atajos de teclado (por IPC, modules/capture).
// Reglas:
//   - Captura: se guarda en Imágenes/Capturas con fecha y hora en el nombre,
//     y queda en el portapapeles. Igual desde el botón que desde el teclado.
//   - De zona: eliges un recorte con el ratón; Esc cancela.
//   - De pantalla: el monitor enfocado entero (como Cmd+Shift+3).
//   - Selector de color: el color queda en el portapapeles.

pragma Singleton

import QtQuick
import Quickshell
import qs.data.hyprland
import qs.data.system

Singleton {
    id: root

    readonly property string folder: "Capturas"

    function fileName(): string {
        return "Captura_" + Qt.formatDateTime(new Date(), "yyyy-MM-dd_HH-mm-ss") + ".png";
    }

    function screenshot(): void {
        CaptureRepository.screenshotRegion(root.folder, root.fileName());
    }

    function screenshotScreen(): void {
        CaptureRepository.screenshotOutput(HyprlandRepository.focusedMonitorName,
                                           root.folder, root.fileName());
    }

    function pickColor(): void {
        CaptureRepository.pickColor();
    }
}
