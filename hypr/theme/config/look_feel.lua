-- ~/.config/hypr/themes/mac/config/look_feel.lua
--
-- Migrado desde themes/mac/config/look_feel.conf (hyprlang -> lua)
-- Ref: https://wiki.hypr.land/Configuring/Basics/Variables/


-----------------
---- GENERAL ----
-----------------

hl.config({
    general = {
        gaps_in  = 5,
        gaps_out = 10,

        -- OJO: tenías -1, que está fuera del rango documentado (ver notas).
        -- Si lo que querías era "sin borde", el valor explícito es 0.
        border_size = -1,

        col = {
            -- rgba(33ccffee) rgba(00ff99ee) 45deg
            active_border   = { colors = { "rgba(33ccffee)", "rgba(00ff99ee)" }, angle = 45 },
            inactive_border = "rgba(595959aa)",
        },

        -- Redimensionar arrastrando bordes y gaps
        resize_on_border = false,

        -- Ver https://wiki.hypr.land/Configuring/Advanced-and-Cool/Tearing/ antes de activarlo
        allow_tearing = false,

        layout = "dwindle",
    },
})


--------------------
---- DECORATION ----
--------------------

hl.config({
    decoration = {
        rounding       = 10,
        rounding_power = 2,

        -- Transparencia de ventanas enfocadas / sin enfocar
        active_opacity   = 1.0,
        inactive_opacity = 1.0,

        shadow = {
            enabled      = true,
            range        = 4,
            render_power = 3,
            -- rgba(1a1a1aee) en hyprlang == 0xee1a1a1a en lua (AARRGGBB)
            color        = 0xee1a1a1a,
        },

        blur = {
            enabled  = true,
            size     = 3,
            passes   = 1,
            vibrancy = 0.1696,
        },
    },
})


--------------------
---- ANIMATIONS ----
--------------------

hl.config({
    animations = {
        enabled = true,
    },
})

-- Curvas. Ref: https://wiki.hypr.land/Configuring/Advanced-and-Cool/Animations/
hl.curve("easeOutQuint",   { type = "bezier", points = { {0.23, 1},    {0.32, 1} } })
hl.curve("easeInOutCubic", { type = "bezier", points = { {0.65, 0.05}, {0.36, 1} } })
hl.curve("linear",         { type = "bezier", points = { {0, 0},       {1, 1}    } })
hl.curve("almostLinear",   { type = "bezier", points = { {0.5, 0.5},   {0.75, 1} } })
hl.curve("quick",          { type = "bezier", points = { {0.15, 0},    {0.1, 1}  } })
hl.curve("appleCurve",     { type = "bezier", points = { {0.25, 1},    {0.5, 1}  } }) -- Apple animation

-- Base
hl.animation({ leaf = "global",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "windowsIn",     enabled = true, speed = 4.1,  bezier = "easeOutQuint", style = "popin 87%" })
hl.animation({ leaf = "fadeIn",        enabled = true, speed = 1.73, bezier = "almostLinear" })
hl.animation({ leaf = "fadeOut",       enabled = true, speed = 1.46, bezier = "almostLinear" })
hl.animation({ leaf = "layers",        enabled = true, speed = 3.81, bezier = "easeOutQuint" })
hl.animation({ leaf = "layersIn",      enabled = true, speed = 4,    bezier = "easeOutQuint", style = "fade" })
hl.animation({ leaf = "layersOut",     enabled = true, speed = 1.5,  bezier = "linear",       style = "fade" })
hl.animation({ leaf = "fadeLayersIn",  enabled = true, speed = 1.79, bezier = "almostLinear" })
hl.animation({ leaf = "fadeLayersOut", enabled = true, speed = 1.39, bezier = "almostLinear" })
hl.animation({ leaf = "zoomFactor",    enabled = true, speed = 7,    bezier = "quick" })

-- Estilo Apple
hl.animation({ leaf = "border",        enabled = true, speed = 10,   bezier = "default" })
hl.animation({ leaf = "windows",       enabled = true, speed = 7,    bezier = "appleCurve" })
hl.animation({ leaf = "windowsOut",    enabled = true, speed = 7,    bezier = "default",      style = "popin 80%" })
hl.animation({ leaf = "fade",          enabled = true, speed = 7,    bezier = "default" })
hl.animation({ leaf = "workspaces",    enabled = true, speed = 6,    bezier = "appleCurve",   style = "slide" })

-- Alternativa que tenías comentada (el set por defecto de Hyprland):
-- hl.animation({ leaf = "border",        enabled = true, speed = 5.39, bezier = "easeOutQuint" })
-- hl.animation({ leaf = "windows",       enabled = true, speed = 4.79, bezier = "easeOutQuint" })
-- hl.animation({ leaf = "windowsOut",    enabled = true, speed = 1.49, bezier = "linear",       style = "popin 87%" })
-- hl.animation({ leaf = "fade",          enabled = true, speed = 3.03, bezier = "quick" })
-- hl.animation({ leaf = "workspaces",    enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })
-- hl.animation({ leaf = "workspacesIn",  enabled = true, speed = 1.21, bezier = "almostLinear", style = "fade" })
-- hl.animation({ leaf = "workspacesOut", enabled = true, speed = 1.94, bezier = "almostLinear", style = "fade" })


-----------------
---- LAYOUTS ----
-----------------

-- https://wiki.hypr.land/Configuring/Layouts/Dwindle-Layout/
hl.config({
    dwindle = {
        -- pseudotile ya no existe en 0.56: se eliminó el interruptor maestro.
        -- El bind SUPER + P (hl.dsp.window.pseudo) funciona sin necesidad de él.
        preserve_split = true,
    },
})

-- https://wiki.hypr.land/Configuring/Layouts/Master-Layout/
hl.config({
    master = {
        new_status = "master",
    },
})


--------------
---- MISC ----
--------------

hl.config({
    misc = {
        force_default_wallpaper = -1,    -- 0 o 1 para desactivar los wallpapers de la mascota
        disable_hyprland_logo   = false,
    },
})