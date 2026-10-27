-- ~/.config/hypr/theme/config/programs.lua
--
-- Apps y comandos que comparten los módulos. Cada uno lo pide con:
--     local p = require("theme.config.programs")

local M = {}

M.mainMod = "SUPER" -- tecla "Windows" (o Cmd en un teclado Mac) como modificador principal

M.terminal     = "warp-terminal"
M.fileManager  = "nautilus"

-- Todo lo de la shell pasa por su IPC (qs ipc call <objetivo> <función>).
-- Así el atajo y el botón de la shell hacen exactamente lo mismo.
M.menu     = "qs ipc call launcher open"
-- Spotlight directo en el modo Portapapeles (como Win + V). Llamarlo otra vez
-- con el portapapeles abierto lo cierra.
M.clipboard = "qs ipc call launcher mode clipboard"
M.settings = "qs ipc call settings toggle"

-- Capturas: se guardan en Imágenes/Capturas y quedan en el portapapeles,
-- igual que el botón del Centro de control. Funciones: region, screen.
M.capture  = "qs ipc call capture"

return M
