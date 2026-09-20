-- ~/.config/hypr/themes/mac/config/workspace_windows_rules.lua
--
-- Migrado desde themes/mac/config/workspace_windows_rules.conf (hyprlang -> lua)
-- Ref: https://wiki.hypr.land/Configuring/Basics/Window-Rules/
--      https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/
--
-- El orden importa: las reglas se evalúan de arriba hacia abajo.


-------------------------
---- WORKSPACE RULES ----
-------------------------

-- "Smart gaps" / "No gaps when only"
-- Descomenta el bloque completo si lo quieres.
-- hl.workspace_rule({ workspace = "w[tv1]", gaps_out = 0, gaps_in = 0 })
-- hl.workspace_rule({ workspace = "f[1]",   gaps_out = 0, gaps_in = 0 })
-- hl.window_rule({
--     name  = "no-gaps-wtv1",
--     match = { float = false, workspace = "w[tv1]" },
--     border_size = 0,
--     rounding    = 0,
-- })
-- hl.window_rule({
--     name  = "no-gaps-f1",
--     match = { float = false, workspace = "f[1]" },
--     border_size = 0,
--     rounding    = 0,
-- })


----------------------
---- WINDOW RULES ----
----------------------

-- Ignora las peticiones de maximizar de todas las apps.
-- Guardamos el handle por si quieres desactivarla sin borrarla.
local suppressMaximizeRule = hl.window_rule({
    name  = "suppress-maximize-events",
    match = { class = ".*" },

    suppress_event = "maximize",
})
-- suppressMaximizeRule:set_enabled(false)

-- Picture-in-Picture del navegador: flotante, fijado y en la esquina
-- El class real de Zen es app.zen_browser.zen (confirmado con hyprctl clients).
-- Strings [[...]] para no tener que escapar dos veces las barras del regex.
hl.window_rule({
    name  = "browser-pip",
    match = {
        class = [[^app\.zen_browser\.zen$]],
        title = [[^(Picture-in-Picture|Imagen sobre imagen)$]],
    },

    float        = true,
    pin          = true,
    size         = "640 360",
    move         = "20 20",          -- esquina superior izquierda
    border_color = "rgb(ff0000)",    -- borde rojo para identificarlo rápido
})

-- Gestor de archivos siempre flotante y centrado
hl.window_rule({
    name  = "nautilus-float",
    match = { class = [[^org\.gnome\.Nautilus$]] },

    float           = true,
    size            = "60% 65%",
    center          = true,
    persistent_size = true,  -- recuerda el tamaño si lo redimensionas
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