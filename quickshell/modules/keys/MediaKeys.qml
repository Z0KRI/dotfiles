// La feature de las teclas especiales: la fila de arriba del teclado Mac (y
// las teclas multimedia de cualquier teclado). Hyprland atrapa la tecla y la
// manda aquí por IPC; la shell hace el trabajo y la isla lo enseña.
//
//   qs ipc call brightness up|down     F1 / F2: brillo (gamma de hyprsunset)
//   qs ipc call media playPause|next|previous   F7 / F8 / F9
//
// El volumen (F10–F12) no pasa por aquí: lo cambia wpctl directo y la isla
// se entera por Pipewire. F4 (Launchpad) abre Spotlight en Aplicaciones con
// el IPC del launcher. Los atajos están en hypr/theme/config/keybindings.lua.
//
// No dibuja nada: es solo la puerta. Por eso es un Scope y no una ventana.
// Se llama MediaKeys y no Keys: Keys ya es de QtQuick (Keys.onPressed…), y
// con el mismo nombre QML tendría que adivinar cuál quieres.

import Quickshell
import Quickshell.Io
import qs.domain.desktop
import qs.domain.media

Scope {
    IpcHandler {
        target: "brightness"

        function up(): void {
            Brightness.step(1);
        }

        function down(): void {
            Brightness.step(-1);
        }
    }

    IpcHandler {
        target: "media"

        function playPause(): void {
            Player.togglePlaying();
        }

        function next(): void {
            Player.next();
        }

        function previous(): void {
            Player.previous();
        }
    }
}
