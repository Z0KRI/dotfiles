#!/usr/bin/env bash
# ~/.config/rofi/scripts/clipboard.sh
#
# Script mode de rofi sobre cliphist: el equivalente del Win+V.
#
# Protocolo de los script modes: rofi llama al script sin argumentos
# para pedir la lista, y lo vuelve a llamar con la línea elegida en $1
# cuando el usuario selecciona algo.
#
# Requiere:  pacman -S cliphist wl-clipboard
# Y el demonio corriendo, en hyprland.lua:
#     exec-once = wl-paste --watch cliphist store

set -euo pipefail

if [[ -z "${1:-}" ]]; then
    # cliphist list devuelve "ID<TAB>vista previa". Mostrar el ID sería
    # ruido, así que va escondido en el campo `info` de rofi, que vuelve
    # en $ROFI_INFO al seleccionar. Así $1 queda solo con el texto.
    cliphist list | while IFS=$'\t' read -r id preview; do
        printf '%s\0info\x1f%s\n' "$preview" "$id"
    done
else
    # Recuperar el contenido completo (no la vista previa recortada) y
    # dejarlo en el portapapeles.
    cliphist decode <<< "${ROFI_INFO:-}" | wl-copy
fi
