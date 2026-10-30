-- ~/.config/hypr/theme/config/look_feel.lua
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

        border_size = 0,

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

        -- Desenfoque de lo translúcido: Spotlight (layer_rule en
        -- workspace_windows_rules.lua) y las ventanas con transparencia.
        -- Más pasadas = más difuso: macOS 27 subió la difusión detrás del
        -- vidrio para que el texto se lea mejor. Cada pasada cuesta GPU; si
        -- notas tirones, baja passes a 2.
        -- variant/proportional NO van: son de la rama en desarrollo, no de 0.56.
        blur = {
            enabled           = true,
            size              = 8,
            passes            = 3,
            noise             = 0.02,   -- un grano leve: el vidrio no se ve plástico
            contrast          = 0.95,
            brightness        = 1.0,
            vibrancy          = 0.22,   -- satura un poco los colores de atrás
            vibrancy_darkness = 0.15,
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