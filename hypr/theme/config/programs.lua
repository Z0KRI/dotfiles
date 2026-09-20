-- ~/.config/hypr/themes/config/programs.lua
--
-- Equivale a las variables $terminal / $fileManager / $menu
-- del hyprlang viejo. En Lua no hay variables globales de config: se exporta
-- una tabla y los demás módulos la piden con require().

local M = {}

M.mainMod = "SUPER" -- tecla "Windows" como modificador principal

M.terminal     = "ghostty"
M.fileManager  = "nautilus"
M.menu = "rofi -show combi -theme ~/.config/rofi/spotlight.rasi"

-- $(xdg-user-dir PICTURES) se deja sin expandir a propósito: exec_cmd lanza
-- el comando por shell, así que la expande al momento de ejecutarse (igual
-- que hacía el .conf viejo).
M.screenshotPath = '"$(xdg-user-dir PICTURES)/Screenshots"'

return M
