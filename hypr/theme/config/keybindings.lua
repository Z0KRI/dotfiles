-- ~/.config/hypr/themes/mac/config/keybindings.lua
--
-- Migrado desde themes/mac/config/keybindigs.conf (hyprlang -> lua)
-- Ref: https://wiki.hypr.land/Configuring/Basics/Binds/
--      https://wiki.hypr.land/Configuring/Basics/Dispatchers/

local p = require("theme.config.programs")

local mainMod        = p.mainMod
local screenshotPath = p.screenshotPath


-------------------
---- SPOTLIGHT ----
-------------------

hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd(p.menu))


-----------------------------
---- SYSTEM FUNDAMENTALS ----
-----------------------------

-- Log out
hl.bind(mainMod .. " + SHIFT + Q", hl.dsp.exit())

-- Cierra la ventana activa y, si el workspace queda vacío, vuelve al 1.
local function closeWindow()
    hl.dispatch(hl.dsp.window.close())
    hl.timer(function()
        local ws = hl.get_active_workspace()
        if ws and ws.is_empty then
            hl.dispatch(hl.dsp.focus({ workspace = 1 }))
        end
    end, { timeout = 100, type = "oneshot" })
end

hl.bind(mainMod .. " + Q", closeWindow)

-- Manda la ventana al primer workspace libre por encima del actual y la pone
-- en fullscreen (estilo Spaces de macOS). Repetir el bind sobre esa misma
-- ventana deshace el modo y la devuelve a su workspace de origen.
-- (antes: scripts/maximize_window.sh)

-- [stable_id de la ventana] = id del workspace del que salió
local maximizedFrom = {}

-- Si la ventana se cierra estando maximizada, soltamos su registro
hl.on("window.close", function(w)
    if w then maximizedFrom[w.stable_id] = nil end
end)

local function maximizeOnFreeWorkspace()
    local win = hl.get_active_window()
    if not win then return end

    local origin = maximizedFrom[win.stable_id]

    -- Ya la habíamos maximizado: deshacer y devolverla a donde estaba.
    -- El workspace temporal queda vacío y Hyprland lo elimina solo.
    if origin then
        maximizedFrom[win.stable_id] = nil
        hl.dispatch(hl.dsp.window.fullscreen({ action = "unset" }))
        hl.timer(function()
            hl.dispatch(hl.dsp.window.move({ workspace = origin }))
        end, { timeout = 100, type = "oneshot" })
        return
    end

    local current = win.workspace
    if not current then return end

    local taken = {}
    for _, ws in pairs(hl.get_workspaces()) do
        taken[ws.id] = true
    end

    local target = current.id + 1
    while taken[target] do
        target = target + 1
    end

    maximizedFrom[win.stable_id] = current.id

    hl.dispatch(hl.dsp.window.move({ workspace = target }))

    hl.timer(function()
        hl.dispatch(hl.dsp.window.fullscreen())
    end, { timeout = 100, type = "oneshot" })
end

hl.bind("CONTROL + " .. mainMod .. " + F", maximizeOnFreeWorkspace)


hl.bind(mainMod .. " + E",      hl.dsp.exec_cmd(p.fileManager))
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd(p.terminal))


---------------------------------
---- MOVING BETWEEN WORKSPACES --
---------------------------------

hl.bind("CONTROL + left",  hl.dsp.focus({ workspace = "m-1" }))
hl.bind("CONTROL + right", hl.dsp.focus({ workspace = "m+1" }))


---------------------
---- SCREENSHOTS ----
---------------------

hl.bind(mainMod .. " + SHIFT + 3", hl.dsp.exec_cmd("hyprshot -m output -o " .. screenshotPath))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("hyprshot -m region -o " .. screenshotPath))


--------------------------------------------
---- MOVE ACTIVE WINDOW TO A WORKSPACE -----
--------------------------------------------

-- SUPER + SHIFT + [0-9]  (el 0 mapea al workspace 10)
for i = 1, 10 do
    local key = i % 10
    hl.bind(mainMod .. " + SHIFT + " .. key, hl.dsp.window.move({ workspace = i }))
end


-------------------------
---- WINDOW ACTIONS -----
-------------------------

hl.bind(mainMod .. " + V", hl.dsp.window.float({ action = "toggle" }))
hl.bind(mainMod .. " + P", hl.dsp.window.pseudo())          -- dwindle
hl.bind(mainMod .. " + J", hl.dsp.layout("togglesplit"))    -- dwindle


-------------------------------------------
---- MOVE FOCUS WITH mainMod + ARROWS -----
-------------------------------------------

hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))


----------------------------------------
---- SPECIAL WORKSPACE (SCRATCHPAD) ----
----------------------------------------

hl.bind(mainMod .. " + S", hl.dsp.workspace.toggle_special("magic"))
-- OJO: este bind choca con el screenshot de región de arriba (ver notas)
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.window.move({ workspace = "special:magic" }))


-------------------------------
---- MOVE WINDOW POSITION -----
-------------------------------

hl.bind(mainMod .. " + SHIFT + left",  hl.dsp.window.swap({ direction = "left" }))
hl.bind(mainMod .. " + SHIFT + right", hl.dsp.window.swap({ direction = "right" }))
hl.bind(mainMod .. " + SHIFT + up",    hl.dsp.window.swap({ direction = "up" }))
hl.bind(mainMod .. " + SHIFT + down",  hl.dsp.window.swap({ direction = "down" }))


-------------------------------
---- RESIZE ACTIVE WINDOW -----
-------------------------------

-- relative = true  ->  x/y son un delta en píxeles (el "resizeactive 100 0" viejo)
hl.bind(mainMod .. " + minus",         hl.dsp.window.resize({ x = -100, y = 0,    relative = true }))
hl.bind(mainMod .. " + plus",          hl.dsp.window.resize({ x = 100,  y = 0,    relative = true }))
hl.bind(mainMod .. " + SHIFT + minus", hl.dsp.window.resize({ x = 0,    y = -100, relative = true }))
hl.bind(mainMod .. " + SHIFT + plus",  hl.dsp.window.resize({ x = 0,    y = 100,  relative = true }))


-----------------------------------------
---- SCROLL THROUGH WORKSPACES ----------
-----------------------------------------

hl.bind(mainMod .. " + mouse_down", hl.dsp.focus({ workspace = "e+1" }))
hl.bind(mainMod .. " + mouse_up",   hl.dsp.focus({ workspace = "e-1" }))


------------------------------------------------
---- MOVE/RESIZE WINDOWS WITH mainMod + LMB/RMB
------------------------------------------------

-- equivalente a bindm
hl.bind(mainMod .. " + mouse:272", hl.dsp.window.drag(),   { mouse = true })
hl.bind(mainMod .. " + mouse:273", hl.dsp.window.resize(), { mouse = true })


-----------------------------
---- MULTIMEDIA KEYS --------
-----------------------------

-- equivalente a bindel: locked = funciona con la pantalla bloqueada,
--                       repeating = se repite si mantienes la tecla
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%+"),   { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-"),   { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle"),  { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle"),{ locked = true, repeating = true })