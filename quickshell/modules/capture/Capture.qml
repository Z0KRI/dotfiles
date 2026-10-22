// La feature de capturas desde el teclado. No dibuja nada: solo abre la
// puerta del IPC para que los atajos de Hyprland hagan lo mismo que los
// botones del Centro de control (las reglas viven en QuickActions).
//
//   qs ipc call capture region   eliges una zona       (SUPER + SHIFT + S)
//   qs ipc call capture screen   el monitor enfocado   (SUPER + SHIFT + 3)
//   qs ipc call capture color    selector de color

import Quickshell
import Quickshell.Io
import qs.domain.desktop

Scope {
    id: root

    IpcHandler {
        target: "capture"

        function region(): void {
            QuickActions.screenshot();
        }

        function screen(): void {
            QuickActions.screenshotScreen();
        }

        function color(): void {
            QuickActions.pickColor();
        }
    }
}
