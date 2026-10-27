-- ~/.config/hypr/hosts/default.lua
--
-- Perfil de respaldo: se carga cuando no existe hosts/<hostname>.lua.
-- También es la plantilla para una máquina nueva:
--     cp hosts/default.lua hosts/$(cat /etc/hostname | cut -d. -f1).lua
--
-- Lo que va en un host: monitores, teclado, qué workspace es primario en cada
-- monitor y cualquier arreglo propio de ese hardware.

local ws = require("theme.config.workspaces")


-----------------
---- TECLADO ----
-----------------

-- Español latinoamericano en las dos máquinas.
-- Para alternar con inglés:  kb_layout = "latam,us", kb_options = "grp:alt_shift_toggle"
hl.config({
    input = {
        kb_layout = "latam",
    },
})


------------------
---- MONITORES ----
------------------

-- Sin reglas: Hyprland usa la resolución preferida de cada pantalla.
-- Para fijarlas, mira los nombres con `hyprctl monitors` y declara, por ejemplo:
--
-- hl.monitor({ output = "HDMI-A-1", mode = "1920x1080@60", position = "0x0",        scale = "1" })
-- hl.monitor({ output = "HDMI-A-2", mode = "1920x1080@60", position = "auto-right", scale = "1" })


-----------------------------
---- WORKSPACES PRIMARIOS ----
-----------------------------

-- El primario de cada monitor se queda siempre en mosaico normal (los demás
-- se ponen en pantalla completa cuando queda una sola ventana).
--
-- Un monitor:
ws.primario(1)
--
-- Dos monitores (crea además la regla workspace -> monitor):
-- ws.primario({ workspace = "1", monitor = "HDMI-A-1" })
-- ws.primario({ workspace = "2", monitor = "HDMI-A-2" })
