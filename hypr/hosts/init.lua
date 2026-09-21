-----------------------------------
---- CONFIG POR MÁQUINA (HOSTS) ----
-----------------------------------
-- Va AL FINAL a propósito: lo que definan los hosts sobrescribe lo general
-- (por ejemplo kb_layout, que arriba está en "us").
--
-- Pon aquí los hostnames reales. Cada uno se ve con:  cat /etc/hostname
local function readHostname()
    local f = io.open("/etc/hostname", "r")
    if not f then
        return nil
    end
    local h = f:read("*l")
    f:close()
    -- solo el nombre corto: "pc.dominio.local" -> "pc"
    return h and h:match("^%s*([^%s.]+)")
end

local host = readHostname()
local profile = host or "default"

-- Sin pcall a propósito: si hosts/<perfil>.lua tiene un error, quieres verlo,
-- no que se trague en silencio y caiga al default.
require("hosts." .. profile)

-- CONFIGURACION DE LA DYNAMIC BAR (K4)
-- hl.unbind("SUPER + Space")
-- hl.bind("SUPER + Space", hl.dsp.exec_cmd(p.menu .. ' -show combi -theme ' .. p.menuPath .. "/spotlight-min.rasi")) 