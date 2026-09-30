pragma Singleton

import Quickshell

Singleton {
    id: root

    readonly property string userName: Quickshell.env("USER") ?? ""

    function lock(): void {
        Quickshell.execDetached(["loginctl", "lock-session"]);
    }

    function suspend(): void {
        Quickshell.execDetached(["systemctl", "suspend"]);
    }

    function reboot(): void {
        Quickshell.execDetached(["systemctl", "reboot"]);
    }

    function powerOff(): void {
        Quickshell.execDetached(["systemctl", "poweroff"]);
    }

    // Termina la sesión actual. Funciona igual con cualquier compositor.
    function logout(): void {
        Quickshell.execDetached(["sh", "-c", "loginctl terminate-session \"$XDG_SESSION_ID\""]);
    }

    // Modo "matar ventana" de Hyprland: la ventana que clickees se cierra a la fuerza.
    function forceQuit(): void {
        Quickshell.execDetached(["hyprctl", "kill"]);
    }
}