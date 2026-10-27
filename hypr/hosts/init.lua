-- ~/.config/hypr/hosts/init.lua
--
-----------------------------------
---- CONFIG POR MÁQUINA (HOSTS) ----
-----------------------------------
-- Se carga AL FINAL de hyprland.lua a propósito: lo que definan los hosts
-- sobrescribe lo general (por ejemplo kb_layout, que por defecto es "us").
--
-- Cada máquina tiene su archivo con el nombre corto de /etc/hostname:
--     hosts/PC-Z0.lua      ->  cat /etc/hostname  ->  PC-Z0
--
-- Esos archivos NO se suben al repo (ver .gitignore): llevan nombres de
-- monitores y cosas propias de cada equipo. Si la máquina no tiene el suyo,
-- se carga hosts/default.lua, que sí está en el repo. Para una máquina nueva:
--     cp hosts/default.lua hosts/$(cat /etc/hostname | cut -d. -f1).lua

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

-- package.searchpath solo BUSCA el archivo, no lo ejecuta. Así distinguimos
-- "esta máquina no tiene perfil" (cae al default) de "el perfil tiene un
-- error" (quieres verlo, no que se trague en silencio): por eso no hay pcall.
local function profileFor(host)
    if host and package.searchpath("hosts." .. host, package.path) then
        return host
    end
    return "default"
end

require("hosts." .. profileFor(readHostname()))

-- Lo que conservas en Ajustes › Pantallas (lo escribe tu shell, también
-- ignorado por git). Va DESPUÉS del perfil a propósito: hl.monitor() de un
-- monitor que ya tiene regla solo cambia los campos que trae, así que pisa
-- lo que tocaste en Ajustes y deja igual lo demás de tu perfil.
-- Para volver al perfil: Ajustes › Pantallas › Restablecer (o borrar el archivo).
if package.searchpath("hosts.displays", package.path) then
    require("hosts.displays")
end
