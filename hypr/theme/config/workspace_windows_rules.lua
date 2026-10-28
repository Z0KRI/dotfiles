-- ~/.config/hypr/theme/config/workspace_windows_rules.lua
--
-- Ref: https://wiki.hypr.land/Configuring/Basics/Window-Rules/
--      https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
--
-- El orden importa: las reglas se evalúan de arriba hacia abajo.

-- La política de fullscreen automático y los workspaces primarios viven en su
-- propio módulo, porque los hosts también necesitan declararlos.
require("theme.config.workspaces")


-------------------------
---- WORKSPACE RULES ----
-------------------------

-- "Smart gaps": si en un workspace solo hay UNA ventana en mosaico, se le
-- quitan gaps, borde y esquinas.
--
-- OJO: r[2-99] asume que el primario es el 1, igual que hacía la tabla vieja.
-- Los selectores de workspace son C++, no pueden consultar la tabla de
-- primarios, así que esto no se puede hacer dinámico. En la máquina del
-- trabajo, el workspace 2 es primario y aun así entra aquí.
-- Es puramente cosmético: afecta a gaps y borde, no al mosaico.
hl.workspace_rule({ workspace = "r[2-99]w[tv1]", gaps_in = 0, gaps_out = 0 })

hl.window_rule({
    name  = "solo-sin-adornos",
    match = { float = false, workspace = "r[2-99]w[tv1]" },

    border_size = 0,
    rounding    = 0,
})


----------------------
---- WINDOW RULES ----
----------------------

-- Ignora las peticiones de maximizar de todas las apps.
hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})

-- Picture-in-Picture del navegador: flotante, fijado y en la esquina
hl.window_rule({
    name  = "browser-pip",
    match = {
        class = [[^app\.zen_browser\.zen$]],
        title = [[^(Picture-in-Picture|Imagen sobre imagen)$]],
    },

    float        = true,
    pin          = true,
    size         = "640 360",
    move         = "20 20",
    border_color = "rgb(ff0000)",
})

-- Gestor de archivos siempre flotante y centrado
hl.window_rule({
    name  = "nautilus-float",
    match = { class = [[^org\.gnome\.Nautilus$]] },

    float           = true,
    size            = "60% 65%",
    center          = true,
    persistent_size = true,
})

-- Ajustes de tu shell (Quickshell): flotante y centrado, como los Ajustes
-- del Sistema de macOS. Quickshell abre sus ventanas con la clase
-- org.quickshell; el título es lo que distingue a esta.
-- Confírmalo con la ventana abierta: hyprctl clients | grep -A4 Ajustes
hl.window_rule({
    name  = "quickshell-settings",
    match = {
        class = [[^org\.quickshell$]],
        title = [[^Ajustes$]],
    },

    float  = true,
    size   = "860 620",
    center = true,
})

-- Arregla problemas de arrastre con XWayland
hl.window_rule({
    name  = "fix-xwayland-drags",
    match = {
        class      = "^$",
        title      = "^$",
        xwayland   = true,
        float      = true,
        fullscreen = false,
        pin        = false,
    },

    no_focus = true,
})

-- Hyprland-run
hl.window_rule({
    name  = "move-hyprland-run",
    match = { class = "hyprland-run" },

    move  = "20 monitor_h-120",
    float = true,
})


---------------------
---- LAYER RULES ----
---------------------

-- Las "capas" son las ventanas de la shell (layer-shell): la barra, la isla,
-- Spotlight. Se reconocen por su namespace, el WlrLayershell.namespace de cada
-- ventana de qs. Ref: https://wiki.hypr.land/Configuring/Basics/Window-Rules/

-- Spotlight: el desenfoque de su Liquid Glass. QML no puede ver lo que hay
-- detrás de su ventana, así que el desenfoque lo pone Hyprland.
--
-- La ventana de Spotlight cubre TODA la pantalla (para cerrar con un clic
-- afuera) y casi toda es transparente. ignore_alpha hace que Hyprland solo
-- desenfoque donde el píxel tiene más alfa que eso: el vidrio (nunca baja de
-- 0.26, ver Theme.liquid) sí, el resto de la pantalla no. Si lo subes por
-- encima de 0.26, el vidrio más transparente del deslizador de Ajustes deja
-- de desenfocar.
hl.layer_rule({
    name  = "spotlight-glass",
    match = { namespace = "z0-launcher" },

    blur         = true,
    ignore_alpha = 0.2,
})
