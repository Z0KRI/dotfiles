pragma Singleton

// ¿hay una ventana en pantalla completa? Una sola respuesta para toda la shell.
//
// Hyprland lo dice en los datos del espacio de trabajo (`hasfullscreen` de
// `hyprctl workspaces -j`), no en los del monitor, así que hay que preguntarle
// al espacio activo de cada pantalla.
//
// Y hay que pedirle que lo relea: Quickshell refresca los espacios cuando pasan
// ciertas cosas, pero entrar y salir de pantalla completa no cambia de espacio
// ni abre ventanas, así que sin escuchar el evento `fullscreen` el dato se
// queda viejo y la regla no se dispara hasta el siguiente cambio de workspace.

import QtQuick
import Quickshell
import Quickshell.Hyprland

Singleton {
    id: root

    // En el monitor donde sale la island, que es el que tiene el foco.
    readonly property bool onFocused: root.onMonitor(
        Hyprland.focusedMonitor ? Hyprland.focusedMonitor.name : "")

    function onMonitor(name): bool {
        const wanted = String(name || "");

        if (wanted.length === 0)
            return false;

        const monitors = Hyprland.monitors;

        for (let i = 0; i < monitors.length; ++i) {
            const monitor = monitors[i];

            if (!monitor || monitor.name !== wanted)
                continue;

            const workspace = monitor.activeWorkspace;
            if (!workspace)
                return false;

            // El JSON crudo del IPC. `hasfullscreen` no está expuesto como
            // propiedad de Quickshell, pero sí viaja en el objeto.
            const raw = workspace.lastIpcObject;
            return !!(raw && raw.hasfullscreen);
        }

        return false;
    }

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            // `fullscreen` es el que nos importa; los otros tres cambian cuál es
            // el espacio activo, y con él la respuesta.
            if (event.name === "fullscreen"
                    || event.name === "workspace"
                    || event.name === "focusedmon"
                    || event.name === "closewindow")
                Hyprland.refreshWorkspaces();
        }
    }
}