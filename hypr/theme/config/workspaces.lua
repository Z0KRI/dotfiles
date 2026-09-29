-- ~/.config/hypr/theme/config/workspaces.lua
--
-- Dos cosas que van juntas:
--   1) qué workspace es el PRIMARIO de cada monitor
--   2) la política de fullscreen automático, que necesita saber lo anterior
--
-- Se declara desde hosts/<maquina>.lua, porque el mapeo monitor <-> workspace
-- es propio de cada máquina.

local M = {}


--------------------------------
---- WORKSPACES PRIMARIOS ------
--------------------------------

-- [id del workspace] = true
-- OJO: esta tabla se MUTA, nunca se reasigna. Los hosts se cargan DESPUÉS
-- que este módulo, así que quien la lea tiene que hacerlo en tiempo de
-- evento (no al cargar), o vería la tabla vacía.
M.primarios = {}

-- Declara el workspace primario de un monitor.
--
--   ws.primario({ workspace = "1", monitor = "HDMI-A-1" })  -> crea la regla
--   ws.primario(1)                                          -> solo lo marca
--
-- Un solo sitio donde decirlo: la regla de workspace y la marca de primario
-- salen de la misma llamada, así no se pueden desincronizar.
function M.primario(t)
    if type(t) ~= "table" then t = { workspace = t } end

    local id = tonumber(t.workspace)
    if not id then return end

    if t.monitor then
        hl.workspace_rule({
            workspace  = tostring(id),
            monitor    = t.monitor,
            persistent = t.persistent ~= false,  -- por defecto sí
            default    = true,
        })
    end

    M.primarios[id] = true
end


----------------------------------------
---- FULLSCREEN AUTOMÁTICO CUANDO SOLO -
----------------------------------------
--
-- Política: en un workspace que NO sea primario, si queda una sola ventana
-- en mosaico, se pone en fullscreen sola. Con dos o más, se deshace.
-- Los primarios (uno por monitor) quedan siempre en mosaico normal.
--
-- Esto NO se puede hacer con una window rule: el efecto `fullscreen` solo se
-- lee en CWindow::mapWindow(), o sea al abrir la ventana, y no se reevalúa
-- cuando cambia el número de ventanas. Por eso va por eventos.

-- Solo cuentan las ventanas en mosaico: las flotantes (Nautilus, el PiP de
-- Zen, hyprland-run) no deben disparar ni bloquear el fullscreen.
local function ventanasEnMosaico(ws)
    local out = {}
    for _, w in pairs(hl.get_workspace_windows(ws)) do
        if not w.floating then
            out[#out + 1] = w
        end
    end
    return out
end

-- w.fullscreen es el modo interno: 0 = ninguno, 1 = maximizado, 2 = fullscreen
local function quitarFullscreen(w)
    if w.fullscreen ~= 0 then
        hl.dispatch(hl.dsp.window.fullscreen({ action = "unset", window = w }))
    end
end

local function aplicarPolitica(ws)
    if ws.special then return end   -- el scratchpad se queda fuera

    local wins = ventanasEnMosaico(ws)
    if #wins == 0 then return end

    -- Lectura en tiempo de evento, no al cargar: para entonces los hosts ya
    -- rellenaron la tabla.
    if M.primarios[ws.id] then
        for _, w in ipairs(wins) do quitarFullscreen(w) end
        return
    end

    if #wins == 1 then
        local w = wins[1]
        if w.fullscreen == 0 then
            -- Mismo truco que el bind de maximizar: apagar sync_fullscreen
            -- ANTES, para que la app nunca se entere y no guarde ese estado.
            hl.dispatch(hl.dsp.window.set_prop({ prop = "sync_fullscreen", value = "false", window = w }))
            hl.dispatch(hl.dsp.window.fullscreen({ action = "set", window = w }))
        end
    else
        for _, w in ipairs(wins) do quitarFullscreen(w) end
    end
end

-- Repasamos TODOS los workspaces en vez de solo el que cambió: al mover una
-- ventana, el evento trae el workspace destino pero no el de origen, que
-- también hay que reevaluar.
--
-- El flag `pendiente` agrupa la ráfaga de eventos en una sola pasada, y el
-- timer da tiempo a que el cierre de ventana se complete antes de contar.
local pendiente = false

function M.repasar()
    if pendiente then return end
    pendiente = true

    hl.timer(function()
        pendiente = false
        for _, ws in pairs(hl.get_workspaces()) do
            aplicarPolitica(ws)
        end
    end, { timeout = 120, type = "oneshot" })
end

hl.on("window.open",              M.repasar)
hl.on("window.close",             M.repasar)
hl.on("window.move_to_workspace", M.repasar)

-- Multimonitor: desconectar o conectar una pantalla reparte los workspaces
-- entre los monitores que quedan, así que hay que recontar.
hl.on("monitor.added",            M.repasar)
hl.on("monitor.removed",          M.repasar)
hl.on("workspace.move_to_monitor", M.repasar)

return M