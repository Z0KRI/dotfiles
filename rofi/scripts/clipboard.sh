#!/usr/bin/env bash
# ~/.config/rofi/scripts/clipboard.sh
#
# Chip de Portapapeles: el equivalente de Win+V. Enter sobre una entrada
# la copia Y la pega en la ventana donde estabas.
#
# Requiere:  pacman -S cliphist wl-clipboard
# Y el vigilante arrancando con la sesión (autostart.lua):
#     hl.on("hyprland.start", function ()
#         hl.exec_cmd("wl-paste --watch cliphist store")
#     end)

# Terminales: pegan con Ctrl+Shift+V. En ellas Ctrl+V no pega, manda un ^V
# literal. Son clases de Hyprland (hyprctl activewindow -j | grep class).
TERMINALES='^(com\.mitchellh\.ghostty|kitty|Alacritty|foot|org\.wezfurlong\.wezterm)$'

# --------------------------------------------------------------------
# Sin argumentos: rofi pide la lista.
# --------------------------------------------------------------------
if [[ -z "${1:-}" ]]; then
    # cliphist list devuelve "ID<TAB>vista previa". Se muestra solo la
    # vista previa, y la línea ORIGINAL completa viaja escondida en el
    # campo info de rofi: es exactamente lo que cliphist decode espera
    # recibir, sin depender de cómo interprete un ID suelto.
    cliphist list | while IFS=$'\t' read -r id preview; do
        printf '%s\0info\x1f%s\t%s\n' "$preview" "$id" "$preview"
    done
    exit 0
fi

# --------------------------------------------------------------------
# Enter sobre una entrada.
# --------------------------------------------------------------------
[[ -z "${ROFI_INFO:-}" ]] && exit 0

# Salida de wl-copy a /dev/null: wl-copy se queda vivo en segundo plano
# sirviendo el portapapeles, y si hereda la salida de rofi, rofi sigue
# leyendo de ella y no se cierra.
printf '%s\n' "$ROFI_INFO" | cliphist decode | wl-copy >/dev/null 2>&1

# El pegado tiene que ocurrir DESPUÉS de que rofi se cierre. Mientras
# rofi está abierto, el foco de teclado es suyo, y send_shortcut sin una
# ventana explícita manda la tecla a quien tenga el foco: el Ctrl+V le
# llegaría a rofi, no a tu aplicación. Y rofi no se cierra hasta que este
# script termina, así que el pegado va en un proceso aparte que espera a
# que muera el padre (rofi lanza el script directamente: $PPID es rofi).
#
# Espera acotada a 2 s por si algún día el padre no fuera rofi.
setsid -f bash -c '
    rofi_pid=$1 terminales=$2
    for _ in $(seq 100); do
        kill -0 "$rofi_pid" 2>/dev/null || break
        sleep 0.02
    done
    sleep 0.05   # margen para que Hyprland devuelva el foco a la ventana

    # Sin jq a propósito: se extrae el campo class con sed.
    clase=$(hyprctl activewindow -j 2>/dev/null \
            | sed -n "s/.*\"class\": *\"\([^\"]*\)\".*/\1/p" | head -n 1)

    mods="CTRL"
    [[ $clase =~ $terminales ]] && mods="CTRL SHIFT"

    # Sintaxis de hyprctl con config en Lua: se le pasa la llamada entera.
    hyprctl dispatch "hl.dsp.send_shortcut({ mods = \"$mods\", key = \"V\" })"
' _ "$PPID" "$TERMINALES" >/dev/null 2>&1 </dev/null

exit 0