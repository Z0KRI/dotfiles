-- ~/.config/hypr/hyprland.lua
--
-- Punto de entrada de Hyprland (config Lua, 0.56+). Este archivo solo carga
-- módulos; cada cosa vive en su archivo:
--
--   theme/config/programs.lua                 apps y comandos compartidos
--   theme/config/look_feel.lua                bordes, sombras, animaciones
--   theme/config/keybindings.lua              atajos
--   theme/config/workspace_windows_rules.lua  reglas de ventanas y workspaces
--   theme/config/workspaces.lua               workspaces primarios + fullscreen automático
--   hosts/init.lua                            lo propio de cada máquina (va al final)
--
-- Ref: https://wiki.hypr.land/Configuring/Start/


------------------
---- MONITORS ----
------------------

-- Los monitores son de cada máquina: viven en hosts/<hostname>.lua.
-- Ref: https://wiki.hypr.land/Configuring/Basics/Monitors/


---------------------
---- MY PROGRAMS ----
---------------------

-- terminal / fileManager / menu viven en theme/config/programs.lua, para que
-- cualquier módulo los comparta. Cada módulo los pide por su cuenta con:
--     local p = require("theme.config.programs")


-------------------
---- AUTOSTART ----
-------------------

-- Ref: https://wiki.hypr.land/Configuring/Basics/Autostart/
--
-- OJO: "hyprland.start" se dispara UNA vez, al arrancar el compositor.
-- `hyprctl reload` no lo vuelve a lanzar: lo que agregues aquí arráncalo a
-- mano la primera vez. Y `exec_cmd` no avisa si el comando falla: pruébalo
-- antes en una terminal.
--
-- BlueFerry no va aquí: su servicio de usuario cuelga de default.target y
-- arranca solo al iniciar sesión.
hl.on("hyprland.start", function ()
    -- Historial del portapapeles (texto e imágenes).
    hl.exec_cmd("wl-paste --watch cliphist store")

    -- Agente de polkit: sin él, Nautilus no puede montar discos.
    hl.exec_cmd("/usr/lib/mate-polkit/polkit-mate-authentication-agent-1")

    -- Brillo y luz nocturna de la shell (gamma). Va ANTES que qs: la shell
    -- le manda lo guardado al arrancar y reintenta a los 3 s.
    -- --identity: sin él arranca con 6000 K de golpe hasta que qs lo corrige.
    hl.exec_cmd("hyprsunset --identity")

    -- Tu shell: barra, isla, Spotlight, Ajustes y notificaciones.
    hl.exec_cmd("qs")
end)


-------------------------------
---- ENVIRONMENT VARIABLES ----
-------------------------------

-- Ref: https://wiki.hypr.land/Configuring/Advanced-and-Cool/Environment-variables/

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")


-----------------------
---- LOOK AND FEEL ----
-----------------------

-- general / decoration / animaciones / layouts / misc viven en su módulo.
require("theme.config.look_feel")

-- El fix del cursor se queda aquí a propósito: no es estética del tema, es un
-- workaround de la máquina de casa (nouveau no pinta el cursor por hardware en
-- la RTX 5060 Ti). Revisar al migrar a nvidia-open-dkms.
hl.config({
    cursor = {
        no_hardware_cursors = true,
    },
})


---------------
---- INPUT ----
---------------

-- El teclado (kb_layout = "latam") y la config por dispositivo van en hosts/:
-- cada máquina declara lo suyo. Lo demás queda con los valores de Hyprland.
--
-- OJO: input.follow_mouse tiene que seguir distinto de 0 (el de fábrica es 1):
-- la isla aparece en el monitor enfocado, y eso es lo que la hace seguir al ratón.

hl.gesture({
    fingers = 3,
    direction = "horizontal",
    action = "workspace"
})


---------------------
---- KEYBINDINGS ----
---------------------

-- Ref: https://wiki.hypr.land/Configuring/Basics/Binds/
require("theme.config.keybindings")


--------------------------------
---- WINDOWS AND WORKSPACES ----
--------------------------------

require("theme.config.workspace_windows_rules")


-----------------------------------
---- CONFIG POR MÁQUINA (HOSTS) ----
-----------------------------------

-- Al final a propósito: lo que definan los hosts sobrescribe lo de arriba.
require("hosts.init")
