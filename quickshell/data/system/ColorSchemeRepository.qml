// REPOSITORIO: el esquema de color que leen las apps (GTK4/libadwaita y
// las que preguntan al portal de escritorio), vía gsettings.

pragma Singleton

import Quickshell

Singleton {
    function setDark(dark): void {
        Quickshell.execDetached([
            "gsettings", "set", "org.gnome.desktop.interface",
            "color-scheme", dark ? "prefer-dark" : "default"
        ]);
    }
}